import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show ChangeNotifier, ValueNotifier, immutable;
import 'package:keycloak_flutter/keycloak_flutter.dart';

/// -----------------------------------
///  Login Info (notifica cambi stato)
/// -----------------------------------
class LoginInfo extends ChangeNotifier {
  var _isInitialized = false;
  var _isLoggedIn = false;
  String? _initError;

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  String? get initError => _initError;

  set isInitialized(bool value) {
    _isInitialized = value;
    notifyListeners();
  }

  set isLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }

  set initError(String? value) {
    _initError = value;
    notifyListeners();
  }
}

/// -----------------------------------
///  Auth Service Singleton
/// -----------------------------------
@immutable
class AuthService {
  static final AuthService instance = AuthService._internal();
  static KeycloakProfile? _keycloakProfile;
  final int _maxRefreshAttempts = 5; // soglia per forzare il logout
  final ValueNotifier<TokenRefreshState> tokenRefreshState =
      ValueNotifier(const TokenRefreshState());

  factory AuthService() {
    return instance;
  }

  final _loginInfo = LoginInfo();

  static final keycloak = KeycloakService(KeycloakConfig(
    url: 'https://auth.storysizer.org',
    realm: 'storysizer',
    clientId: 'storysizer',
  ));

  get loginInfo => _loginInfo;

  AuthService._internal();

  Future<void> init() async {
    _wipeStaleKeycloakStorage();
    keycloak.keycloakEventsStream.listen((event) async => handleEvent(event));

    try {
      await keycloak
          .init(
            initOptions: KeycloakInitOptions(
              onLoad: 'check-sso',
              responseMode: 'query',
              checkLoginIframe: false,
              // Keep init fast and deterministic across browsers/private modes.
              messageReceiveTimeout: 3000,
              // Required for check-sso to stay silent (iframe flow).
              silentCheckSsoRedirectUri:
                  'https://app.storysizer.org/silent-check-sso.html',
              // Safari private mode blocks 3p cookies; without this, Keycloak
              // falls back to a top-level prompt=none redirect that can end on
              // an invalid credentials page.
              silentCheckSsoFallback: false,
            ),
          )
          .timeout(const Duration(seconds: 6));
      // Some browsers may not fire onReady; ensure the flag is set on success.
      _loginInfo.isInitialized = true;
      _loginInfo.initError = null;
    } on TimeoutException catch (e) {
      // If check-sso does not complete in time, keep the login UI usable.
      print('Keycloak init timeout, continuing without SSO check: $e');
      _loginInfo.initError = null;
      _loginInfo.isInitialized = true;
    } catch (e) {
      // ignore: avoid_print
      print('Keycloak init failed: $e');
      _loginInfo.initError = e.toString();
    }
  }

  Future<void> login({String? idpHint}) async {
    final options = KeycloakLoginOptions(redirectUri: Uri.base.origin);
    if (idpHint != null) options.idpHint = idpHint;
    keycloak.login(options);
  }

  Future<void> logout() async {
    try {
      await keycloak.logout();
    } catch (e) {
      print("Errore logout: $e");
    }
  }

  Future<String> getAccessToken() async {
    if (!keycloak.authenticated) {
      await login();
    }
    // Aggiorna il token se scade nei prossimi 30s
    await keycloak.updateToken(60);
    return keycloak.getToken();
  }

  Future<void> handleEvent(KeycloakEvent event) async {
    switch (event.type) {
      case KeycloakEventType.onReady:
        _handleReady();
        break;
      case KeycloakEventType.onAuthSuccess:
        await _handleAuthSuccess();
        break;
      case KeycloakEventType.onAuthLogout:
        _handleAuthLogout();
        break;
      case KeycloakEventType.onTokenExpired:
        await _handleTokenExpired();
        break;
      case KeycloakEventType.onAuthRefreshSuccess:
        _handleAuthRefreshSuccess();
        break;
      case KeycloakEventType.onAuthRefreshError:
        await _handleAuthRefreshError();
        break;
      default:
        break;
    }
  }

  void _handleReady() {
    _loginInfo.isInitialized = true;
  }

  Future<void> _handleAuthSuccess() async {
    _keycloakProfile = await keycloak.loadUserProfile();
    _loginInfo.isLoggedIn = true;
    tokenRefreshState.value = tokenRefreshState.value.copyWith(
      isRefreshing: false,
      failureCount: 0,
    );
  }

  void _handleAuthLogout() {
    _keycloakProfile = null;
    _loginInfo.isLoggedIn = false;
  }

  Future<void> _handleTokenExpired() async {
    if (!tokenRefreshState.value.isRefreshing) {
      tokenRefreshState.value =
          tokenRefreshState.value.copyWith(isRefreshing: true);
      try {
await keycloak.updateToken(60);
      } catch (e) {
        print("Errore refresh token: $e");
        await _handleAuthRefreshError();
      } finally {
        tokenRefreshState.value =
            tokenRefreshState.value.copyWith(isRefreshing: false);
      }
    }
  }

  void _handleAuthRefreshSuccess() {
    tokenRefreshState.value = tokenRefreshState.value.copyWith(
      isRefreshing: false,
      failureCount: 0,
    );
  }

  Future<void> _handleAuthRefreshError() async {
    final newFailureCount = tokenRefreshState.value.failureCount + 1;
    tokenRefreshState.value =
        tokenRefreshState.value.copyWith(isRefreshing: false, failureCount: newFailureCount);
    if (newFailureCount >= _maxRefreshAttempts) {
      _forceLogout();
    } else {
      try {
await keycloak.updateToken(60);
      } catch (e) {
        print("Errore nuovo tentativo refresh: $e");
      }
    }
  }

  void _forceLogout() {
    logout();
    _keycloakProfile = null;
    _loginInfo.isLoggedIn = false;
  }

  /// Removes stale Keycloak entries from local/session storage left over from
  /// previous app versions or aborted login flows. These leftovers can cause
  /// `keycloak-js` to hang or fail in browsers like Safari (normal mode) where
  /// ITP partitions cookies in iframes while leaving local storage populated.
  ///
  /// Only runs when the current URL is NOT an OAuth callback (no `code`,
  /// `state` or `session_state` in the query/fragment), so we never break a
  /// legitimate login redirect flow.
  void _wipeStaleKeycloakStorage() {
    try {
      final uri = Uri.base;
      final params = <String, String>{
        ...uri.queryParameters,
        ...Uri.splitQueryString(uri.fragment),
      };
      final isCallback = params.containsKey('code') ||
          params.containsKey('state') ||
          params.containsKey('session_state') ||
          params.containsKey('error');
      if (isCallback) return;

      bool isKcKey(String? k) =>
          k != null && (k.startsWith('kc-') || k.startsWith('keycloak'));

      final ls = html.window.localStorage;
      ls.keys.where(isKcKey).toList().forEach(ls.remove);

      final ss = html.window.sessionStorage;
      ss.keys.where(isKcKey).toList().forEach(ss.remove);
    } catch (e) {
      // ignore: avoid_print
      print('Wipe stale Keycloak storage failed: $e');
    }
  }

  /// -----------------------------------
  ///  getUserProfile
  /// -----------------------------------
  Future<Map<String, String>> getUserProfile() async {
    try {
      if (_keycloakProfile == null) {
        if (!keycloak.authenticated) {
          print("Utente non autenticato.");
          return {
            "id": "N/A",
            "username": "Utente sconosciuto",
            "firstName": "",
            "lastName": "",
          };
        }
        _keycloakProfile = await keycloak.loadUserProfile(false);
      }

      final userProfile = {
        "id": _keycloakProfile?.id ?? "N/A",
        "username": _keycloakProfile?.username ?? "Utente sconosciuto",
        "firstName": _keycloakProfile?.firstName ?? "",
        "lastName": _keycloakProfile?.lastName ?? "",
      };

      return userProfile;
    } catch (e) {
      print("Errore nel recupero del profilo utente: $e");
      return {
        "id": "Errore",
        "username": "Errore nel caricamento",
        "firstName": "",
        "lastName": "",
      };
    }
  }
}

/// -----------------------------------
///  Stato Refresh Token
/// -----------------------------------
@immutable
class TokenRefreshState {
  final bool isRefreshing;
  final int failureCount;

  const TokenRefreshState({
    this.isRefreshing = false,
    this.failureCount = 0,
  });

  TokenRefreshState copyWith({
    bool? isRefreshing,
    int? failureCount,
  }) {
    return TokenRefreshState(
      isRefreshing: isRefreshing ?? this.isRefreshing,
      failureCount: failureCount ?? this.failureCount,
    );
  }
}
