import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:storysizer/services/auth_service.dart';
import 'helpers/is_debug.dart';
import 'helpers/theme.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart'; // importiamo i provider definiti

class StorySizer extends ConsumerWidget {
  const StorySizer({super.key});  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Utilizziamo ref.watch per recuperare i provider

    return MaterialApp.router(
      routerConfig: ref.watch(routesProvider).router,
      debugShowCheckedModeBanner: false,
      themeMode: ref.watch(themeModeProvider).mode,
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
          Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.empty);
        }
      };

      await AuthService.instance.init();

      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp],);

      setUrlStrategy(PathUrlStrategy()); 
      runApp(
        ProviderScope(
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
