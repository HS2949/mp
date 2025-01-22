import 'package:flutter/foundation.dart';
import 'package:mp_db/models/custom_error.dart';
import 'package:mp_db/providers/signup/signup_state.dart';
import 'package:mp_db/repositories/auth_repository.dart';

class SignupProvider with ChangeNotifier {
  SignupState _state = SignupState.initial();
  SignupState get state => _state;

  final AuthRepository authRepository;
  SignupProvider({
    required this.authRepository,
  });

  Future<void> signup({
    required String name,
    required String position,
    required String email,
    required String password,
  }) async {
    _state = _state.copyWith(signupStatus: SignupStatus.submitting);
    notifyListeners();

    try {
      await authRepository.signup(name: name, position: position, email: email, password: password);
      _state = _state.copyWith(signupStatus: SignupStatus.success);
      notifyListeners();
    } on CustomError catch (e) {
      _state = _state.copyWith(signupStatus: SignupStatus.error, error: e);
      notifyListeners();
    } catch (e) {
      // 예상치 못한 오류 처리
      _state = _state.copyWith(
        signupStatus: SignupStatus.error,
        error: CustomError(
          code: 'unknown-error',
          message: '알 수 없는 오류가 발생했습니다.',
        ),
      );
      notifyListeners();
    }
  }
}
