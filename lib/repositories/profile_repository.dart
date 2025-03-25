import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mp_db/models/custom_error.dart';
import 'package:mp_db/models/user_model.dart';

class ProfileRepository {
  final FirebaseFirestore firebaseFirestore;
  final usersRef = FirebaseFirestore.instance.collection('users');
  ProfileRepository({
    required this.firebaseFirestore,
  });

  Future<User> getProfile({required String uid}) async {
    try {
      final DocumentSnapshot userDoc = await usersRef.doc(uid).get();
      print('데이터 읽기 ');
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
