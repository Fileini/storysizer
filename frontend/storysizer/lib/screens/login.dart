import 'dart:ui';
import 'dart:html' as html; // per aprire i link su Flutter Web

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import 'package:sign_in_button/sign_in_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(75),
                  child: Stack(
                    children: [
                      Image.asset(
                        "assets/logo.png",
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(75),
                            border: Border.all(
                              width: 5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "StorySizer",
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ),
                const LoginButton(),
              ],
            ),
            // ToS + Privacy nell'angolo in basso a destra
            Positioned(
              right: 8,
              bottom: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      html.window.open(
                          'https://storysizer.org/terms-of-use', '_blank');
                    },
                    child: const Text(
                      "Terms of Service",
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
                  const Text("·",
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  TextButton(
                    onPressed: () {
                      html.window.open(
                          'https://storysizer.org/privacy-policy', '_blank');
                    },
                    child: const Text(
                      "Privacy Policy",
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    final loginInfo = AuthService.instance.loginInfo;
    return ListenableBuilder(
      listenable: loginInfo,
      builder: (context, _) {
        if (loginInfo.initError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  const Text(
                    'Authentication service unavailable',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loginInfo.initError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reload'),
                    onPressed: () => html.window.location.reload(),
                  ),
                ],
              ),
            ),
          );
        }
        return Center(
          child: loginInfo.isInitialized
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IdpButton(
                      type: Buttons.gitHub,
                      onPressed: () =>
                          AuthService.instance.login(idpHint: 'github'),
                    ),
                    const SizedBox(height: 8),
                    _IdpButton(
                      type: Buttons.google,
                      onPressed: () =>
                          AuthService.instance.login(idpHint: 'google'),
                    ),
                    const SizedBox(height: 8),
                    _IdpButton(
                      type: Buttons.microsoft,
                      onPressed: () =>
                          AuthService.instance.login(idpHint: 'microsoft'),
                    ),
                    const SizedBox(height: 8),
                    _IdpButton(
                      type: Buttons.apple,
                      badgeLabel: 'coming later',
                      onPressed: () => context.go('/coming-soon/Apple'),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        );
      },
    );
  }
}

class _IdpButton extends StatelessWidget {
  final Buttons type;
  final VoidCallback onPressed;
  final String? badgeLabel;

  const _IdpButton({
    required this.type,
    required this.onPressed,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 250,
          height: 40,
          child: SignInButton(
            type,
            clipBehavior: Clip.hardEdge,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: onPressed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        if (badgeLabel != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeLabel!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
