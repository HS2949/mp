import 'package:flutter/cupertino.dart';

class AppTheme {
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

  static const EdgeInsets popupPadding = EdgeInsets.all(16); // 팝업 기본 패딩
}
