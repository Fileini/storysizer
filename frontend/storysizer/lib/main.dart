import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:storysizer/services/auth_service.dart';
import 'helpers/is_debug.dart';
import 'helpers/theme.dart';
import 'routes.dart';

class StorySizer extends StatelessWidget {
  const StorySizer({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: StszRoutes().router,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: getTheme(),
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
      runApp(const StorySizer());
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
