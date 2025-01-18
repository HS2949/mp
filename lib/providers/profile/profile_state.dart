import 'package:mp_db/models/custom_error.dart';
import 'package:mp_db/models/user_model.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  error,
}

class ProfileState {
  ProfileState({
    required this.profileStatus,
    required this.user,
    required this.error,
  });

  final ProfileStatus profileStatus;
  final User user;
  final CustomError error;

  factory ProfileState.initial() {
    return ProfileState(
      profileStatus: ProfileStatus.initial,
      user: User.initialUser(),
      error: CustomError(),
    );
  }

  @override
  List<Object?> get props => [profileStatus, user, error];

  @override
  bool get stringify => true;

  ProfileState copyWith(
      {ProfileStatus? profileStatus, User? user, CustomError? error}) {
    return ProfileState(
        profileStatus: profileStatus ?? this.profileStatus,
        user: user ?? this.user,
        error: error ?? this.error);
  }
}
