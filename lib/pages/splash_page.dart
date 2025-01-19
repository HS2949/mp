import 'package:flutter/material.dart';
import 'package:mp_db/pages/home.dart';
import 'package:mp_db/pages/signin_page.dart';
import 'package:mp_db/providers/auth/auth_provider.dart';
import 'package:mp_db/providers/auth/auth_state.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  static const String routeName = '/';

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthProvider>().state;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.authStatus == AuthStatus.authenticated) {
        Navigator.pushReplacementNamed(context, Home.routeName);
      } else if (authState.authStatus == AuthStatus.unauthenticated) {
        Navigator.pushReplacementNamed(context, SigninPage.routeName);
      }
    });

    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            strokeWidth: 4.0,
          ),
        ),
      ),
    );
  }
}
