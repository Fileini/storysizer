import 'package:flutter/foundation.dart' show ChangeNotifier, ValueNotifier, immutable;
import 'package:keycloak_flutter/keycloak_flutter.dart';

/// -----------------------------------
///  Login Info (notifica cambi stato)
/// -----------------------------------
class LoginInfo extends ChangeNotifier {
  var _isInitialized = false;
  var _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;

  set isInitialized(bool value) {
    _isInitialized = value;
    notifyListeners();
  }

  set isLoggedIn(bool value) {
    _isLoggedIn = value;
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
    keycloak.keycloakEventsStream.listen((event) async => handleEvent(event));

    // Race the keycloak.init against a hard timeout. Some browsers (Chrome with
    // 3rd-party cookies disabled, or strict tracking protection) cause the
    // 3p-cookies iframe to fail loading, which makes init() hang for ~10s
    // before falling back. We unblock the UI after 4s so the login button
    // shows up; silent SSO still works in the background where browsers allow it.
    final initFuture = keycloak.init(
      initOptions: KeycloakInitOptions(
        onLoad: 'check-sso',
        responseMode: 'query',
        checkLoginIframe: false,
        // Cap the wait for 3p-cookies probe (default is 10000ms).
        messageReceiveTimeout: 3000,
        // Top-level navigation page on same origin (no 3P cookies needed).
        silentCheckSsoRedirectUri:
            'https://app.storysizer.org/silent-check-sso.html',
      ),
    );

    try {
      await initFuture.timeout(const Duration(seconds: 4));
    } catch (e) {
      // Init didn't complete in time (or threw). Show the UI anyway.
      // ignore: avoid_print
      print('Keycloak init timed out / failed: $e — proceeding without SSO check');
      _loginInfo.isInitialized = true;
    }
  }

  Future<void> login() async {
    keycloak.login(KeycloakLoginOptions(
      redirectUri: Uri.base.origin,
    ));
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
            "firstName": "Utente sconosciuto",
            "lastName": "Utente sconosciuto",
          };
        }
        _keycloakProfile = await keycloak.loadUserProfile(false);
      }

      final userProfile = {
        "id": _keycloakProfile?.id ?? "N/A",
        "username": _keycloakProfile?.username ?? "Utente sconosciuto",
        "firstName": _keycloakProfile?.firstName ?? "Utente sconosciuto",
        "lastName": _keycloakProfile?.lastName ?? "Utente sconosciuto",
      };

      return userProfile;
    } catch (e) {
      print("Errore nel recupero del profilo utente: $e");
      return {
        "id": "Errore",
        "username": "Errore nel caricamento",
        "firstName": "Errore nel caricamento",
        "lastName": "Errore nel caricamento",
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
