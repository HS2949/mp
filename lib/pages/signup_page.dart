import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/models/custom_error.dart';

import 'package:mp_db/providers/signup/signup_provider.dart';
import 'package:mp_db/providers/signup/signup_state.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:validators/validators.dart';
import 'package:provider/provider.dart';
import '../utils/error_dialog.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  static const String routeName = '/signup';

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;
  String? _name, _position, _email, _password;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController1 = TextEditingController();
  final TextEditingController _passwordController2 = TextEditingController();

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

    print('name: $_name, email: $_email, password: $_password');
    try {
      await context.read<SignupProvider>().signup(
          name: _name!,
          position: _position!,
          email: _email!,
          password: _password!);
      if (mounted) {
        // 로그인 성공 시 이메일 저장
        await _saveEmail(_email!);
        Navigator.pushNamed(context, '/');
      }
    } on CustomError catch (e) {
      errorDialog(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signupState = context.watch<SignupProvider>().state;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Sign Up'),
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
                      'assets/images/miceplan_font.png',
                      width: 250,
                      height: 60,
                      fit: BoxFit.scaleDown,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.error,
                            size: 50, color: Colors.orange);
                      },
                    ),
                    SizedBox(height: 10.0),
                    Center(child: Text('사용자 등록', style: AppTheme.titleMediumTextStyle,)),
                    SizedBox(height: 50.0),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                        hintText: '이메일을 입력해 주세요.',
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
                      controller: _nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Name',
                        hintText: '성함을 입력하세요.',
                        prefixIcon: Icon(Icons.people_alt),
                        suffixIcon: ClearButton(controller: _nameController),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return '성함을 입력하세요.';
                        }
                        return null;
                      },
                      onSaved: (String? value) {
                        _name = value;
                      },
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      controller: _positionController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Position',
                        hintText: '예) 부장, 차장, 매니저 등 .. ',
                        prefixIcon: Icon(Icons.people_alt),
                        suffixIcon:
                            ClearButton(controller: _positionController),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return '직급을 입력하세요.';
                        }
                        return null;
                      },
                      onSaved: (String? value) {
                        _position = value;
                      },
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      obscureText: true,
                      controller: _passwordController1,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          labelText: 'Password',
                          hintText: '비밀번호를 입력해 주세요',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon:
                              ClearButton(controller: _passwordController1)),
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
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      obscureText: true,
                      controller: _passwordController2,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon:
                              ClearButton(controller: _passwordController2)),
                      validator: (String? value) {
                        if (_passwordController1.text != value) {
                          return '비밀번호가 일치하지 않습니다.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30.0),
                    ElevatedButton(
                      onPressed:
                          signupState.signupStatus == SignupStatus.submitting
                              ? null
                              : _submit,
                      child: Text(
                          signupState.signupStatus == SignupStatus.submitting
                              ? 'Loading...'
                              : 'Sign Up'),
                    ),
                    SizedBox(height: 10.0),
                    TextButton(
                      onPressed:
                          signupState.signupStatus == SignupStatus.submitting
                              ? null
                              : () {
                                  Navigator.pop(context);
                                },
                      style: TextButton.styleFrom(
                        textStyle: TextStyle(
                          fontSize: 16.0,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      child: Text('Already a member? Sign in!',
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
    );
  }
}
