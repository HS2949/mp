import 'package:flutter/material.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';



//텍스트필드 지우기 버튼튼
class ClearButton extends StatelessWidget {
  const ClearButton({Key? key, required this.controller}) : super(key: key);

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        // 텍스트가 비어있지 않을 때만 아이콘을 표시
        return value.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear,
                    color: AppTheme.primaryColor, size: 15),
                onPressed: () => controller.clear(),
                focusNode: FocusNode(skipTraversal: true), // 탭 키 포커스 스킵
              )
            : const SizedBox.shrink(); // 빈 위젯 반환
      },
    );
  }
}

//삭제 버튼 onpressd
void FiDeleteDialog({
  required BuildContext context,
  required String collectionName,
  required String documentId,
  required FirestoreService firestoreService, // FirestoreService 인수 추가
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('삭제 확인'),
        content: Text('정말로 이 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 대화상자 닫기
            },
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              firestoreService.deleteItem(
                collectionName: collectionName,
                documentId: documentId,
              );
              Navigator.of(context).pop(); // 대화상자 닫기
            },
            child: Text('삭제'),
          ),
        ],
      );
    },
  );
}


