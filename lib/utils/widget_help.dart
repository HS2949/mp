// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mp_db/constants/styles.dart';
// 숫자 포맷을 위한 패키지

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
Future<void> FiDeleteDialog({
  required BuildContext context,
  required Future<void> Function() deleteFunction,
  bool shouldCloseScreen = false,
}) async {
  return showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('삭제 확인'),
        content: Text('정말로 이 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
            },
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await deleteFunction(); // 삭제 함수 실행
                Navigator.of(dialogContext).pop(); // 다이얼로그 닫기

                if (shouldCloseScreen) {
                  Navigator.of(context).pop(); // 이전 화면도 닫기
                }

                showOverlayMessage(context, "삭제 완료");
              } catch (e) {
                showOverlayMessage(context, "삭제 중 오류 발생: ${e.toString()}");
              }
            },
            child: Text('삭제', style: TextStyle(color: AppTheme.errorColor)),
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
      left: 0, // 좌측 제약 추가
      right: 0, // 우측 제약 추가
      child: Center(
        // 자식 컨테이너를 가운데 정렬
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: AppTheme.textLabelStyle.copyWith(
                color: AppTheme.appbarbackgroundColor,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // 1초 후 자동 제거
  Future.delayed(const Duration(seconds: 1), () {
    overlayEntry.remove();
  });
}

///url에서 파일이름 추출출
String urlFileName(String url) {
  Uri uri = Uri.parse(url);

  // encodedPath가 이미 디코딩된 상태라면 바로 split 가능
  String encodedPath = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
  return encodedPath.split('/').last;
}
