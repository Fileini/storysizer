import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
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
    return Observer(builder: (context) {
      final loginInfo = AuthService.instance.loginInfo;

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
    });
  }
}
