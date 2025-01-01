// Flutter의 Cupertino 스타일 위젯 라이브러리 임포트
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

// Firebase 초기화를 위한 라이브러리 임포트
import 'package:firebase_core/firebase_core.dart';

// 홈 화면의 위젯이 정의된 파일 임포트

// Firebase 초기화 옵션이 정의된 파일 임포트
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'widget/dialog.dart';

// main 함수는 Flutter 앱의 진입점입니다.
void main() async {
  // Flutter의 위젯 바인딩을 초기화합니다. 비동기 작업 전에 반드시 호출해야 합니다.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase를 초기화합니다. Firebase를 사용하려면 앱 실행 전에 반드시 초기화해야 합니다.
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform, // 플랫폼에 따라 설정된 Firebase 옵션 사용
  );

  // 앱을 실행합니다. MyApp 위젯이 루트 위젯이 됩니다.
  runApp(const MyApp());
}

// MyApp 클래스는 StatelessWidget을 상속받아 애플리케이션의 전체 구조를 정의합니다.
class MyApp extends StatelessWidget {
  // const 생성자를 사용해 MyApp 객체를 생성합니다. 불변 객체로 메모리 최적화에 유리합니다.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cupertino 스타일을 사용하는 Flutter 앱의 루트 위젯을 정의합니다.
    return const CupertinoApp(
      // 앱의 제목을 정의합니다. iOS에서는 표시되지 않을 수 있습니다.
      title: '마이스플랜 MICE PLAN',

      // 앱의 테마를 설정합니다.
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemGrey, // 주요 색상을 회색으로 설정
        barBackgroundColor: CupertinoColors.systemGrey6, // 앱 바 배경색을 밝은 회색으로 설정
        textTheme: CupertinoTextThemeData(
          primaryColor: CupertinoColors.systemGrey, // 텍스트의 주요 색상을 회색으로 설정
        ),
      ),

      debugShowCheckedModeBanner: false,
      // 앱의 초기 화면을 설정합니다. HomeScreen 위젯이 시작 화면으로 사용됩니다.
      home: HomeScreen(),
      //home: TestScreen(),
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Test Example Usage'),
      ),
      child: Center(
        child: CupertinoButton(
          child: const Text('Show Dialog'),
          onPressed: () {
            // exampleUsage 호출
            exampleUsage(context, "testItemId"); // 테스트용 ID로 설정
          },
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
