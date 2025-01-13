import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // 색상 변수 정의
  static const Color primaryColor = Color(0xFF6200EE); // 보라색
  static const Color secondaryColor = Color(0xFF03DAC6); // 청록색
  static const Color errorColor = Color(0xFFB00020); // 빨간색
  static const Color backgroundColor = Color(0xFFF5F5F5); // 연한 회색
  static const Color textColor = Color(0xFF333333); // 어두운 텍스트
  static const double textfieldRadious = 10.0;

// 전역 테마 설정
  static ThemeData get mpTheme {
    return ThemeData(
      primaryColor: Colors.grey, // 주요 색상
      scaffoldBackgroundColor: Colors.grey[100], // 화면 배경색
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[50], // 앱 바 배경색
        foregroundColor: Colors.grey, // 앱 바 아이콘과 텍스트 색상
        titleTextStyle: subtitleTextStyle,
      ),
      textTheme: TextTheme(
        bodyLarge:
            TextStyle(color: Colors.grey, fontSize: 14), // bodyLarge 텍스트 스타일
        bodyMedium:
            TextStyle(color: Colors.grey, fontSize: 14), // bodyMedium 텍스트 스타일
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.grey, // 주요 색상
        secondary: Colors.grey[600]!, // 보조 색상
        surface: Colors.grey[50]!, // 표면 색상
      ),
      iconTheme: IconThemeData(color: Colors.grey), // 아이콘 색상

      inputDecorationTheme: InputDecorationTheme(
        // TextField 스타일
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(textfieldRadious),
          borderSide: BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(textfieldRadious),
          borderSide: BorderSide(color: Colors.grey, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(textfieldRadious),
          borderSide: BorderSide(color: Colors.grey, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(textfieldRadious),
          borderSide: BorderSide(color: Colors.grey, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(textfieldRadious),
          borderSide: BorderSide(color: Colors.grey, width: 1.5),
        ),
        isDense: true, // 높이를 줄이는 옵션
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        errorStyle: errorTextStyle, // 에러 메시지 스타일 적용
        prefixIconColor: Colors.grey,
        labelStyle: textfieldStyle,
        
      ),
    );
  }

  // 텍스트 스타일

  static const TextStyle keyTextStyle = TextStyle(
    fontSize: 13, // 글자 크기
    fontWeight: FontWeight.w200, // 글자 두께
    color: Color.fromARGB(255, 0, 0, 0), // 글자 색상
    fontFamily: '맑은글꼴', // 글꼴
  );

  static const TextStyle valueTextStyle = TextStyle(
    fontSize: 13, // 글자 크기
    fontWeight: FontWeight.w200, // 글자 두께
    color: Color.fromARGB(255, 19, 117, 202), // 글자 색상
    fontFamily: '맑은글꼴', // 글꼴
  );

  static const TextStyle titleTextStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: CupertinoColors.black, // 기본 텍스트 색상
  );

  static const TextStyle subtitleTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: CupertinoColors.systemGrey, // 서브 텍스트 색상
  );

  static const TextStyle errorTextStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: Color.fromARGB(255, 150, 20, 63), // 서브 텍스트 색상
  );

  // 팝업 스타일
  static const TextStyle popupTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: CupertinoColors.activeBlue, // 팝업 제목 색상
  );

  static const TextStyle popupMessageStyle = TextStyle(
    fontSize: 16,
    color: CupertinoColors.systemGrey,
  );

  static const TextStyle textfieldStyle = TextStyle(
    fontSize: 13,
    color: CupertinoColors.systemGrey,
  );

  static const EdgeInsets popupPadding = EdgeInsets.all(16); // 팝업 기본 패딩
}
