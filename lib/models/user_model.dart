// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String profileImage;
  final String position;
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImage,
    required this.position,
  });

  factory User.fromDoc(DocumentSnapshot userDoc) {
    final userData = userDoc.data() as Map<String, dynamic>?;

    return User(
      id: userDoc.id,
      name: userData!['name'],
      email: userData['email'],
      profileImage: userData['profileImage'],
      position: userData['position'],
    );
  }

  factory User.initialUser() {
    return User(
      id: '',
      name: '',
      email: '',
      profileImage: '',
      position: '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        profileImage,
        position,
      ];

  @override
  bool get stringify => true;
}
