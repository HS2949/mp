// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:intl/intl.dart'; // 숫자 포맷을 위한 패키지

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
              color: AppTheme.primaryColor.withOpacity(0.7),
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

String formatNumber(String value) {
  // 각 줄별로 처리하기 위해 줄 단위로 분리
  List<String> lines = value.split('\n');
  // 숫자 부분과 괄호 부분을 분리하는 정규표현식
  RegExp regExp = RegExp(r'^([\d,]+)(\s*\(.*\))?$');

  List<String> formattedLines = lines.map((line) {
    Match? match = regExp.firstMatch(line);
    if (match != null) {
      String numberPart = match.group(1)!; // 숫자 및 콤마 포함 부분
      String? suffix = match.group(2); // 괄호를 포함한 접미사 (null일 수 있음)

      // 콤마 제거 후 순수 숫자 문자열 추출
      String numberStr = numberPart.replaceAll(',', '');
      if (RegExp(r'^\d+$').hasMatch(numberStr)) {
        try {
          int number = int.parse(numberStr);
          String formattedNumber = NumberFormat('#,###').format(number);
          return formattedNumber + (suffix ?? '');
        } catch (e) {
          return line; // 변환 중 오류 발생 시 원래 줄 반환
        }
      }
    }
    // 정규표현식에 맞지 않거나 숫자 이외의 문자가 있는 경우 원래 줄 반환
    return line;
  }).toList();

  // 처리한 각 줄을 다시 개행 문자로 연결하여 반환
  return formattedLines.join('\n');
}

enum TextWidgetType { selectable, plain, textField }

/// 길게 눌렀을 때 텍스트를 클립보드에 복사하는 텍스트 위젯을 반환합니다.
/// [widgetType]에 따라 SelectableText, Text, 혹은 TextField를 사용할 수 있습니다.
Widget copyTextWidget(
  BuildContext context, {
  required String text,
  required TextWidgetType widgetType,
  TextStyle? style,
  int maxLines = 1,
  // TextField일 경우 외부에서 controller를 지정할 수 있도록 함.
  TextEditingController? controller,
}) {
  Widget child;

  switch (widgetType) {
    case TextWidgetType.selectable:
      child = SelectableText(
        text,
        style: style,
        maxLines: maxLines,
      );
      break;
    case TextWidgetType.plain:
      child = Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
      break;
    case TextWidgetType.textField:
      child = TextField(
        controller: controller ?? TextEditingController(text: text),
        style: style,
        maxLines: maxLines == 0 ? null : maxLines,
        readOnly: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          filled: false,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      );
      break;
  }

  return GestureDetector(
    onLongPress: () {
      Clipboard.setData(ClipboardData(text: text));
      showOverlayMessage(context, "클립보드 복사");
    },
    child: child,
  );
}
