import 'package:flutter/cupertino.dart';

import '../constants/styles.dart';


void showDynamicCupertinoDialog({
  required BuildContext context,
  required String title,
  required List<Map<String, dynamic>> fields,
  required List<Map<String, dynamic>> actions,
}) {
  // 컨트롤러 생성
  List<TextEditingController> controllers = fields.map((field) {
    // 초기값 설정
    return TextEditingController(text: field.values.first ?? '');
  }).toList();

  showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text(
          title,
          style: AppTheme.subtitleTextStyle,
        ), // 다이얼로그 제목
        content: Column(
          children: [
            for (int i = 0; i < fields.length; i++)
              Column(
                children: [
                  CupertinoTextField(
                    controller: controllers[i],
                    prefix: SizedBox(
                      width: 70, // 고정 너비 설정
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          fields[i].keys.first, // prefix로 key 설정
                          style: AppTheme.keyTextStyle,
                        ),
                      ),
                    ),
                    placeholder: 'Enter value', // 기본 placeholder
                    style: AppTheme.valueTextStyle,
                  ),
                  if (i != fields.length - 1)
                    const SizedBox(height: 10), // 간격 추가
                ],
              ),
          ],
        ),
        actions: [
          for (var action in actions)
            CupertinoDialogAction(
              onPressed: () {
                if (action['onPressed'] != null) {
                  action['onPressed'](controllers);
                }
                Navigator.pop(context);
              },
              child: Text(action['text'] ?? 'Action'),
            ),
        ],
      );
    },
  );
}
