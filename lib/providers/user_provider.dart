// user_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider extends ChangeNotifier {
  List<DocumentSnapshot> _users = [];
  List<DocumentSnapshot> get users => _users;

  StreamSubscription? _userSubscription;

  // 생성자에서 Firestore 구독 시작
  UserProvider() {
    _listenToUsers();
  }

  // Firestore의 'users' 컬렉션을 구독하여 데이터가 변경될 때마다 업데이트
  void _listenToUsers() {
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      _users = snapshot.docs;
      notifyListeners();
    });
  }

  /// userId를 받아서 이름과 직책을 반환하는 함수
  String getUserName(String userId) {
    for (var userDoc in _users) {
      final data = userDoc.data() as Map<String, dynamic>;
      if (userDoc.id == userId) {
        return '${data['name']} ${data['position']}님';
      }
    }
    return '?'; // 해당 userId가 없을 경우
  }

  // Provider가 dispose될 때 Firestore 구독도 취소
  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
