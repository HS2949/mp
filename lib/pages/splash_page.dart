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
        // body: Center(
        //   child: SizedBox(
        //     width: 100,
        //     height: 100,
        //     child: CircularProgressIndicator(
        //       strokeWidth: 4.0,
        //     ),
        //   ),
        // ),
        body: Center(
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Image.asset(
            'assets/images/loading.gif',
            width: 50,
            height: 50,
            fit: BoxFit.contain, // 이미지 비율 유지
          ),
        ),
      ),
    ));
  }
}
