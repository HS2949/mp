// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fbAuth;

import 'package:mp_db/providers/auth/auth_state.dart';
import 'package:mp_db/providers/profile/profile_provider.dart';
import 'package:mp_db/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  AuthState _state = AuthState.unknown();
  AuthState get state => _state;

  final AuthRepository authRepository;
  AuthProvider({
    required this.authRepository,
  });

// AuthProvider에서 사용자 정보 업데이트 이후 프로필 데이터를 자동으로 가져오도록 설정
  void update(fbAuth.User? user, ProfileProvider profileProvider) {
    if (user != null &&
        (_state.authStatus != AuthStatus.authenticated ||
            _state.user?.uid != user.uid)) {
      _state = _state.copyWith(
        authStatus: AuthStatus.authenticated,
        user: user,
      );

      // ProfileProvider의 getProfile 호출을 지연
      Future.microtask(() async {
        try {
          await profileProvider.getProfile(uid: user.uid);
        } catch (error) {
          print('프로필 정보를 가져오는 중 오류 발생: $error');
        }
      });
    } else if (user == null &&
        _state.authStatus != AuthStatus.unauthenticated) {
      _state = _state.copyWith(authStatus: AuthStatus.unauthenticated);
    } else {
      // 동일한 상태일 경우 notifyListeners를 호출하지 않음
      return;
    }
    print('■■■ authState: $_state');
    notifyListeners();
  }

  void signout() async {
    await authRepository.signout();
  }
}
