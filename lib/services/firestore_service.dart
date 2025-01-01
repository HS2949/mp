import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getCategories() async {
    final query = await _db.collection('Categories').get();
    // 불필요한 캐스팅 제거
    return query.docs.map((doc) => doc.data()).toList();
  }

  Future<void> addItem(Map<String, dynamic> data) async {
    await _db.collection('Items').add(data);
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await _db.collection('Items').doc(id).update(data);
  }

  Future<void> deleteItem(String id) async {
    await _db.collection('Items').doc(id).delete();
  }
}
