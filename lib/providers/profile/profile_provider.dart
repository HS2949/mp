import 'package:flutter/material.dart';
import 'package:mp_db/models/custom_error.dart';
import 'package:mp_db/models/user_model.dart';
import 'package:mp_db/providers/profile/profile_state.dart';
import 'package:mp_db/repositories/profile_repository.dart';

class ProfileProvider with ChangeNotifier {
  ProfileState _state = ProfileState.initial();
  ProfileState get state => _state;

  final ProfileRepository profileRepository;
  ProfileProvider({
    required this.profileRepository,
  });

  Future<void> getProfile({required String uid}) async {
    _state = _state.copyWith(profileStatus: ProfileStatus.loading);
    notifyListeners();

    try {
      final User user = await profileRepository.getProfile(uid: uid);

      _state = _state.copyWith(profileStatus: ProfileStatus.loaded, user: user);
      notifyListeners();
    } on CustomError catch(e) {
      _state = _state.copyWith(profileStatus:  ProfileStatus.error, error: e);
      notifyListeners();
    }
  }
}
