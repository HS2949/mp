import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/pages/signup_page.dart';
import 'package:mp_db/providers/signin/signin_provider.dart';
import 'package:mp_db/providers/signin/signin_state.dart';
import 'package:validators/validators.dart';
import 'package:provider/provider.dart';
import '../utils/error_dialog.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});
  static const String routeName = '/signin';

  @override
  _SigninPageState createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final _formKey = GlobalKey<FormState>();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  String? _email, _password;
  String? _emailError, _passwordError;

  void _submit() async {
  setState(() {
    _autovalidateMode = AutovalidateMode.always;
    _emailError = _validateEmail(_email);
    _passwordError = _validatePassword(_password);
  });

  if (_emailError != null || _passwordError != null) return;

  final form = _formKey.currentState;
  if (form == null || !form.validate()) return;

  form.save();

  print('email: $_email, password: $_password');

  await context.read<SigninProvider>().signin(
    email: _email!,
    password: _password!,
  );

  final signinState = context.read<SigninProvider>().state;

  if (signinState.signinStatus == SigninStatus.error) {
    if (mounted) {
      errorDialog(context, signinState.error);
    }
  } else if (signinState.signinStatus == SigninStatus.success) {
    if (mounted) {
      Navigator.pushNamed(context, '/home');
    }
  }
}



  String? _validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return '이메일 주소가 필요합니다';
    }
    if (!isEmail(email.trim())) {
      return '유효한 이메일 주소를 입력하세요';
    }
    return null;
  }

  String? _validatePassword(String? password) {
    if (password == null || password.trim().isEmpty) {
      return '비밀번호를 입력하세요';
    }
    if (password.trim().length < 4) {
      return '비밀번호는 최소 4자 이상이어야 합니다.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final signinState = context.watch<SigninProvider>().state;
    return PopScope(
      canPop : false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text('Sign In'),
          ),
          child: Center(
            child: SizedBox(
              width: 350, // 최대 폭을 500으로 설정
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidateMode,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      SizedBox(height: 50.0),
                      Image.asset(
                        'assets/images/miceplan_logo.png',
                        width: 250,
                        height: 250,
                        fit: BoxFit.scaleDown,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.error, size: 50, color: Colors.red);
                        },
                      ),
                      SizedBox(height: 50.0),
                      CupertinoTextField(
                        keyboardType: TextInputType.emailAddress,
                        placeholder: 'Email',
                        prefix: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(CupertinoIcons.mail),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _email = value;
                            _emailError = _validateEmail(value);
                          });
                        },
                        decoration: BoxDecoration(
                          border: Border.all(color: CupertinoColors.systemGrey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      if (_emailError != null)
                        Padding(
                          padding: EdgeInsets.only(top: 5.0),
                          child: Text(
                            _emailError!,
                            style: AppTheme.errorTextStyle,
                          ),
                        ),
                      SizedBox(height: 20.0),
                      CupertinoTextField(
                        obscureText: true,
                        placeholder: 'Password',
                        prefix: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(CupertinoIcons.lock),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _password = value;
                            _passwordError = _validatePassword(value);
                          });
                        },
                        decoration: BoxDecoration(
                          border: Border.all(color: CupertinoColors.systemGrey),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      if (_passwordError != null)
                        Padding(
                          padding: EdgeInsets.only(top: 5.0),
                          child: Text(
                            _passwordError!,
                            style: AppTheme.errorTextStyle,
                          ),
                        ),
                      SizedBox(height: 30.0),
                      CupertinoButton.filled(
                        onPressed:
                            signinState.signinStatus == SigninStatus.submitting
                                ? null
                                : _submit,
                        child: Text(
                          signinState.signinStatus == SigninStatus.submitting
                              ? 'Loading...'
                              : 'Sign In',
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.0),
                      CupertinoButton(
                        onPressed:
                            signinState.signinStatus == SigninStatus.submitting
                                ? null
                                : () {
                                    Navigator.pushNamed(
                                        context, SignupPage.routeName);
                                  },
                        child: Text(
                          'Not a member? Sign up!',
                          style: TextStyle(
                            fontSize: 16.0,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
