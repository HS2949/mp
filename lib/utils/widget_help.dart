// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
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
  required Future<void> Function() deleteFunction,
  bool shouldCloseScreen = false, // 창을 닫을지 여부 선택 가능
}) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      // 다이얼로그 내부 컨텍스트
      return AlertDialog(
        title: Text('삭제 확인'),
        content: Text('정말로 이 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // 다이얼로그만 닫기
            },
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await deleteFunction(); // 삭제 함수 실행

              Navigator.of(dialogContext).pop(); // 다이얼로그 닫기

              if (shouldCloseScreen) {
                Navigator.of(context).pop(); // 이전 화면도 닫기
              }
            },
            child: Text('삭제'),
          ),
        ],
      );
    },
  );
}

// ScaffoldMessenger.of(context)
//     .showSnackBar(
//   const SnackBar(
//       content: Text("값을 입력해주세요.")),
// );
void showOverlayMessage(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).size.height * 0.4,
      left: MediaQuery.of(context).size.width * 0.3,
      right: MediaQuery.of(context).size.width * 0.3,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              message,
              style: AppTheme.textLabelStyle
                  .copyWith(color: AppTheme.appbarbackgroundColor),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // 2초 후 자동 제거
  Future.delayed(const Duration(seconds: 2), () {
    overlayEntry.remove();
  });
}
