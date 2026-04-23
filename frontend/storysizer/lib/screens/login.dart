import 'dart:ui';
import 'dart:html' as html; // per aprire i link su Flutter Web

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:sign_in_button/sign_in_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
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
            // Sezione link Terms + Privacy
            Column(
              children: [
                TextButton(
                  onPressed: () {
                    html.window.open('/terms.html', '_blank');
                  },
                  child: const Text(
                    "Terms of Service",
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    html.window.open('/privacy.html', '_blank');
                  },
                  child: const Text(
                    "Privacy Policy",
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
            const LoginButton(),
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
              ? SizedBox(
                  width: 250,
                  height: 50,
                  child: SignInButton(
                    Buttons.google,
                    clipBehavior: Clip.hardEdge,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: () {
                      AuthService.instance.login();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : const CircularProgressIndicator(),
        );
      },
    );
  }
}
