import 'package:flutter/foundation.dart';
import 'package:mp_db/models/custom_error.dart';
import 'package:mp_db/providers/signin/signin_state.dart';
import 'package:mp_db/repositories/auth_repository.dart';

class SigninProvider with ChangeNotifier {
  SigninState _state = SigninState.initial();
  SigninState get state => _state;

  final AuthRepository authRepository;
  SigninProvider({
    required this.authRepository,
  });

  Future<void> signin({
    required String email,
    required String password,
  }) async {
    _state = _state.copyWith(signinStatus: SigninStatus.submitting);
    notifyListeners();

    try {
      await authRepository.signin(email: email, password: password);
      _state = _state.copyWith(signinStatus: SigninStatus.success);
      notifyListeners();
    } on CustomError catch (e) {
      _state = _state.copyWith(signinStatus: SigninStatus.error, error: e);
      notifyListeners();
    } catch (e) {
      // 예상치 못한 오류 처리
      _state = _state.copyWith(
        signinStatus: SigninStatus.error,
        error: CustomError(
          code: 'unknown-error',
          message: '알 수 없는 오류가 발생했습니다.',
        ),
      );
      notifyListeners();
    }
  }
}
