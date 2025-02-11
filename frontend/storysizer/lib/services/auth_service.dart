import 'package:flutter/foundation.dart' show ChangeNotifier, ValueNotifier, immutable;
import 'package:keycloak_flutter/keycloak_flutter.dart';

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
  final _LoginInfo = LoginInfo();

  static final keycloak = KeycloakService(KeycloakConfig(
    url: 'https://keycloak.public.cluster.local.com',
    realm: 'storysizer',
    clientId: 'storysizer',
  ));

  get loginInfo => _LoginInfo;

  AuthService._internal();

  Future<void> init() async {
    
    keycloak.keycloakEventsStream.listen((event) async => handleEvent(event));

    await keycloak.init(
      initOptions: KeycloakInitOptions(
        onLoad: 'check-sso',
        responseMode: 'query',
        silentCheckSsoRedirectUri: '${Uri.base.origin}/silent-check-sso.html',
      ),
    );




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
      // log error
    }
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
        _handleTokenExpired();
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
    _LoginInfo.isInitialized = true;
  }

  Future<void> _handleAuthSuccess() async {
    _keycloakProfile = await keycloak.loadUserProfile();
    _LoginInfo.isLoggedIn = true;
    // Resetta il contatore di errori al login avvenuto con successo.
    tokenRefreshState.value = tokenRefreshState.value.copyWith(
      isRefreshing: false,
      failureCount: 0,
    );
  }

  void _handleAuthLogout() {
    _keycloakProfile = null;
    _LoginInfo.isLoggedIn = false;
  }

  void _handleTokenExpired() {
    if (!tokenRefreshState.value.isRefreshing) {
      tokenRefreshState.value =
          tokenRefreshState.value.copyWith(isRefreshing: true);
      keycloak.updateToken();
      keycloak.updateToken();
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
      await keycloak.updateToken();
    }
  }
  void _forceLogout() {
    // Pulizia dello stato e logout forzato
    logout();
    _keycloakProfile = null;
    _LoginInfo.isLoggedIn = false;
  }



  /// -----------------------------------
  ///  8- getUserProfile
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

      print('Profilo utente: $userProfile');
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

