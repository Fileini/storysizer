import 'package:flutter/foundation.dart' show ChangeNotifier, immutable;
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

  factory AuthService() {
    return instance;
  }
  final _LoginInfo = LoginInfo();

  static final keycloak = KeycloakService(KeycloakConfig(
    url: 'http://keycloak.cluster.local.com',
    realm: 'storysizer',
    clientId: 'storysizer',
  ));

  get loginInfo => _LoginInfo;

  AuthService._internal();

  Future<void> init() async {
    
    keycloak.keycloakEventsStream.listen((event) async {
      print("🔹 Evento Keycloak: ${event.type}");

      switch (event.type) {

        case KeycloakEventType.onReady:
            _LoginInfo.isInitialized = true;

        case KeycloakEventType.onAuthSuccess:
          _keycloakProfile = await keycloak.loadUserProfile();
          _LoginInfo.isLoggedIn = true;
          break;

        case KeycloakEventType.onAuthLogout:
          _keycloakProfile = null;
          _LoginInfo.isLoggedIn = false;
          break;

        case KeycloakEventType.onTokenExpired:
          print("⚠️ Token scaduto. Tentativo di rinnovo...");
          bool refreshed = await keycloak.updateToken();
          if (!refreshed) {
            print("Token non rinnovabile, eseguo logout.");
            logout();
          }
          break;

        default:
          break;
      }
    });

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
              _LoginInfo.isLoggedIn = false;

    try {
      await keycloak.logout();
    } catch (e) {
      // log error
    }
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
