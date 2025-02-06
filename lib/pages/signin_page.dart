import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/pages/signup_page.dart';
import 'package:mp_db/providers/signin/signin_provider.dart';
import 'package:mp_db/providers/signin/signin_state.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email') ?? '';
    setState(() {
      _emailController.text = savedEmail;
    });

    if (savedEmail.isNotEmpty) {
      // FocusScope.of(context).requestFocus(_passwordFocusNode);
    }
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
  }

  void _submit() async {
    setState(() {
      _autovalidateMode = AutovalidateMode.always;
    });

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
        // 로그인 성공 시 이메일 저장
        await _saveEmail(_email!);
        Navigator.pushNamed(context, '/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final signinState = context.watch<SigninProvider>().state;
    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text('Sign In', style: AppTheme.appbarTitleTextStyle),
            centerTitle: true,
          ),
          body: Center(
            child: SizedBox(
              width: 400, // 최대 폭을 500으로 설정
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidateMode,
                  child: ListView(
                    reverse: true,
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    children: [
                      SizedBox(height: 50.0),
                      Image.asset(
                        'assets/images/miceplan_logo.png',
                        width: 250,
                        height: 250,
                        fit: BoxFit.scaleDown,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.error,
                              size: 50, color: Colors.orange);
                        },
                      ),
                      SizedBox(height: 50.0),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          suffixIcon: ClearButton(controller: _emailController),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return '이메일 주소가 필요합니다';
                          }
                          if (!isEmail(value.trim())) {
                            return '유효한 이메일 주소를 입력하세요';
                          }
                          return null;
                        },
                        onSaved: (String? value) {
                          _email = value;
                        },
                      ),
                      SizedBox(height: 20.0),
                      TextFormField(
                        obscureText: true,
                        controller: _passwordController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon:
                              ClearButton(controller: _passwordController),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return '비밀번호를 입력하세요';
                          }
                          if (value.trim().length < 6) {
                            return '비밀번호는 최소 6자 이상이어야 합니다';
                          }
                          return null;
                        },
                        onSaved: (String? value) {
                          _password = value;
                        },
                        // 엔터키로 sign in _submit 호출출
                        onFieldSubmitted: (_) {
                          if (signinState.signinStatus !=
                              SigninStatus.submitting) {
                            _submit(); // _submit() 함수 호출
                          }
                        },
                      ),
                      SizedBox(height: 30.0),
                      ElevatedButton(
                        onPressed:
                            signinState.signinStatus == SigninStatus.submitting
                                ? null
                                : _submit,
                        child: Text(
                            signinState.signinStatus == SigninStatus.submitting
                                ? 'Loading...'
                                : 'Sign In'),
                      ),
                      SizedBox(height: 10.0),
                      TextButton(
                        onPressed:
                            signinState.signinStatus == SigninStatus.submitting
                                ? null
                                : () {
                                    Navigator.pushNamed(
                                        context, SignupPage.routeName);
                                  },
                        style: TextButton.styleFrom(
                          textStyle: TextStyle(
                            fontSize: 16.0,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        child: Text('Not a member? Sign up!',
                            style: AppTheme.textLabelStyle),
                      ),
                      SizedBox(height: 10)
                    ].reversed.toList(),
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
