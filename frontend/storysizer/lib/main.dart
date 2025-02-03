import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:storysizer/services/auth_service.dart';
import 'helpers/is_debug.dart';
import 'helpers/theme.dart';
import 'routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';




class ThemeModeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeMode get mode => _mode;
  bool get isInitialized => _isInitialized;

  ThemeModeProvider() {
    _loadTheme();
  }

  void changeMode(bool isDarkMode) {
    _mode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _saveTheme(isDarkMode);
    notifyListeners();
  }

  Future<void> _loadTheme() async {
  final prefs = await SharedPreferences.getInstance();
  ThemeMode newMode;

  if (!prefs.containsKey('isDarkMode')) {
    // Se è la prima volta, prendi il valore dal sistema
    final Brightness systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    newMode = systemBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  } else {
    final isDark = prefs.getBool('isDarkMode') ?? false;
    newMode = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  if (_mode != newMode || !_isInitialized) { // ✅ Controllo extra per evitare blocchi
    _mode = newMode;
    _isInitialized = true;
    notifyListeners();
  }
}
  Future<void> _saveTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }
}

class StorySizer extends StatelessWidget {
  const StorySizer({super.key});  

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeModeProvider>(context);
    final routerProvider = Provider.of<StszRoutes>(context);

    return MaterialApp.router(
      routerConfig: routerProvider.router,
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.mode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
    );
  }
}

Future<void> main() async {
  BindingBase.debugZoneErrorsAreFatal = true;

  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (FlutterErrorDetails details) {
        if (isInDebugMode) {
          print('Caught Framework Error!');
          FlutterError.dumpErrorToConsole(details);
        } else {
          Zone.current.handleUncaughtError(
              details.exception, details.stack ?? StackTrace.empty);
        }
      };

      await AuthService.instance.init();

      await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp],
      );
      setUrlStrategy(PathUrlStrategy()); // 🔥 Aggiunge PathUrlStrategy per Flutter Web

      runApp(
       MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ThemeModeProvider()),
      Provider<StszRoutes>(create: (context) => StszRoutes()),
    ],
    child: const StorySizer(),
  ),
      
      );
    },
    (error, stackTrace) async {
      print('Caught Dart Error!');
      print('$error');
      print('$stackTrace');
    },
  );

  FlutterError.onError = (FlutterErrorDetails details) async {
    final dynamic exception = details.exception;
    final StackTrace? stackTrace = details.stack;
    if (isInDebugMode) {
      print('Caught Framework Error!');
      FlutterError.dumpErrorToConsole(details);
    } else {
      Zone.current.handleUncaughtError(exception, stackTrace!);
    }
  };
}
