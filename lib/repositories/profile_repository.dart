import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mp_db/constants/db_contants.dart';
import 'package:mp_db/models/custom_error.dart';
import 'package:mp_db/models/user_model.dart';

class ProfileRepository {
  final FirebaseFirestore firebaseFirestore;
  ProfileRepository({
    required this.firebaseFirestore,
  });

  Future<User> getProfile({required String uid}) async {
    try {
      final DocumentSnapshot userDoc = await usersRef.doc(uid).get();
      final User currentUser = User.fromDoc(userDoc);

      return currentUser;
    } on FirebaseException catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.message!,
        plugin: e.plugin,
      );
    } catch (e) {
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_errro/server_error',
      );
    }
  }
}
