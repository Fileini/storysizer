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
            Image.asset(
              "assets/logo.png",
              height: 150,
              width: 150,
            ),
            Text("StorySizer",
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
            ? SignInButton(
                Buttons.google,
                onPressed: () {
                  AuthService.instance.login();
                },
              )
            : const CircularProgressIndicator(), // 🔥 Mostra la rotella di caricamento
      );
    });
  }
}