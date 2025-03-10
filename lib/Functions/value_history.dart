import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mp_db/providers/auth/auth_provider.dart';

Future<void> recordHistory({
  required BuildContext context,
  required String itemId,
  String? subItemId,
  required String field,
  required dynamic before,
  required dynamic after,
}) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final user = authProvider.state.user;
  final userId = user?.uid ?? "unknown";

  CollectionReference historyRef = FirebaseFirestore.instance
      .collection('Items')
      .doc(itemId)
      .collection('history');

  final historyRecord = {
    if (subItemId != null) 'subItemId': subItemId,
    'field': field,
    'userId': userId,
    'timestamp': FieldValue.serverTimestamp(),
    'before': before,
    'after': after,
  };

  await historyRef.add(historyRecord);
}
