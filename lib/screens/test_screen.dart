// Flutter의 Cupertino 스타일 위젯 라이브러리 임포트
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../widget/dialog.dart';

// 홈 화면의 위젯이 정의된 파일 임포트

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Test Example Usage'),
      ),
      child: Center(
        child: ListView(
          children: [
            CupertinoTextField(),
            SizedBox(height: 20),
            CupertinoButton(
              child: const Text('Show Dialog'),
              onPressed: () {
                // exampleUsage 호출
                exampleUsage(context, "testItemId"); // 테스트용 ID로 설정
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 사용 예시
void exampleUsage(BuildContext context, String itemId) {
  showDynamicCupertinoDialog(
    context: context,
    title: "Edit Item",
    fields: [
      {'이름': '이창림'},
      {'지역': '제주'},
      {'전화번호ㄹㅇㄴㅁㄻㄴㄻ': '010-4692-2949'},
      {'직책': '테스트'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
      {'직책': '차장'},
    ],
    actions: [
      {
        'text': 'Cancel',
        'onPressed': (controllers) {
          // 취소 버튼 로직
          print('Canceled');
        },
      },
      {
        'text': 'Save',
        'onPressed': (controllers) async {
          // Firestore 데이터 업데이트 로직
          await FirebaseFirestore.instance
              .collection('Items')
              .doc(itemId)
              .update({
            'ItemName': controllers[0].text,
            'Location': controllers[1].text,
            'PhoneNumber': controllers[2].text,
          });
          print('Saved');
        },
      },
    ],
  );
}
