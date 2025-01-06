import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/providers/signup/signup_provider.dart';
import 'package:mp_db/providers/signup/signup_state.dart';
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
  String? _name, _email, _password ;
  String? _nameError, _emailError, _passwordError, _repasswordError;
  final _passwordController = TextEditingController();

  void _submit() async {
    setState(() {
      _autovalidateMode = AutovalidateMode.always;
    });

    if (_nameError != null || _emailError != null || _passwordError != null|| _repasswordError != null) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    form.save();

    print('name: $_name, email: $_email, password: $_password');

    await context.read<SignupProvider>().signup(
          name: _name!,
          email: _email!,
          password: _password!,
        );

    final signupState = context.read<SignupProvider>().state;

    if (signupState.signupStatus == SignupStatus.error) {
      if (mounted) {
        errorDialog(context, signupState.error);
      }
    } else if (signupState.signupStatus == SignupStatus.success) {
      if (mounted) {
        Navigator.pushNamed(context, '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final signupState = context.watch<SignupProvider>().state;
    return GestureDetector(
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
                      placeholder: 'Name',
                      prefix: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.account_box_rounded),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _name = value;
                          if (value.trim().isEmpty) {
                            _nameError = '이름을 입력하세요';
                          } else if (value.trim().length < 2) {
                            _nameError = '이름은 최소 2자 이상이어야 합니다';
                          } else {
                            _nameError = null;
                          }
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
                      keyboardType: TextInputType.emailAddress,
                      placeholder: 'Email',
                      prefix: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(CupertinoIcons.mail),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _email = value;
                          if (value.trim().isEmpty) {
                            _emailError = '이메일 주소가 필요합니다';
                          } else if (!isEmail(value.trim())) {
                            _emailError = '유효한 이메일 주소를 입력하세요';
                          } else {
                            _emailError = null;
                          }
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
                      controller: _passwordController,
                      obscureText: true,
                      placeholder: 'Password',
                      prefix: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(CupertinoIcons.lock),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _password = value;
                          if (value.trim().isEmpty) {
                            _passwordError = '비밀번호를 입력하세요';
                          } else if (value.trim().length < 6) {
                            _passwordError = '비밀번호는 최소 6자 이상이어야 합니다';
                          } else {
                            _passwordError = null;
                          }
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
                    SizedBox(height: 20.0),
                    CupertinoTextField(
                      obscureText: true,
                      placeholder: 'Confirm Password',
                      prefix: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(CupertinoIcons.lock),
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (_passwordController.text != value) {
                            _repasswordError = '비밀번호가 일치하지 않습니다';
                          } else {
                            _repasswordError = null;
                          }
                        });
                      },
                      decoration: BoxDecoration(
                        border: Border.all(color: CupertinoColors.systemGrey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    if (_repasswordError != null)
                      Padding(
                        padding: EdgeInsets.only(top: 5.0),
                        child: Text(
                          _repasswordError!,
                          style: AppTheme.errorTextStyle,
                        ),
                      ),
                    SizedBox(height: 30.0),
                    CupertinoButton.filled(
                      onPressed:
                          signupState.signupStatus == SignupStatus.submitting
                              ? null
                              : _submit,
                      child: Text(
                        signupState.signupStatus == SignupStatus.submitting
                            ? 'Loading...'
                            : 'Sign Up',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.0),
                    CupertinoButton(
                      onPressed:
                          signupState.signupStatus == SignupStatus.submitting
                              ? null
                              : () {
                                  Navigator.pop(context);
                                },
                      child: Text(
                        'Alread a member? Sign In!',
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
    );
  }
}
