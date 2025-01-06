import 'package:flutter/cupertino.dart';
import 'package:mp_db/pages/home_page.dart';
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
    if (authState.authStatus == AuthStatus.authenticated) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        Navigator.pushNamed(context, HomePage.routeName);
      });
    } else if (authState.authStatus == AuthStatus.unauthenticated) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        Navigator.pushNamed(context, SigninPage.routeName);
      });
    }
    return CupertinoPageScaffold(
        child: Center(
      child: CupertinoActivityIndicator(
        radius: 40.0,
      ),
    ));
  }
}
