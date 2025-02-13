import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


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
        title: Text(title), // 다이얼로그 제목
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
                        ),
                      ),
                    ),
                    placeholder: 'Enter value', // 기본 placeholder
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

//material dialog 버전전
void showTransparentDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor:
        Colors.black.withAlpha((0.3 * 255).toInt()), // Background transparency
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor:
            Colors.white.withAlpha((0.8 * 255).toInt()), // Dialog transparency
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Transparent Dialog",
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              Text(
                "This dialog has a transparent background!",
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.0),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Close"),
              ),
            ],
          ),
        ),
      );
    },
  );
}
