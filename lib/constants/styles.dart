import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum IconLabel {
  smile('Smile', Icons.sentiment_satisfied_outlined),
  cloud('Cloud', Icons.cloud_outlined),
  brush('Brush', Icons.brush_outlined),
  heart('Heart', Icons.favorite),
  list('List', Icons.list),
  bus('Bus', Icons.directions_bus_filled_outlined),
  restaurant('Restaurant', Icons.restaurant),
  place('Place', Icons.mode_of_travel_outlined),
  travel('Travel', Icons.attractions_outlined),
  cafe('Cafe', Icons.local_cafe_outlined),
  activity('Activity', Icons.rowing_outlined),
  // travel('Travel', Icons.attractions_outlined),
  // travel('Travel', Icons.attractions_outlined),

  hotel('Hotel', Icons.hotel_outlined);

  const IconLabel(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum ColorLabel {
  blue('Blue', Colors.blue),
  pink('Pink', Colors.pink),
  green('Green', Colors.green),
  yellow('Yellow', Colors.yellow),
  grey('Grey', Colors.grey),
  red('Red', Colors.red),
  orange('Orange', Colors.orange),
  indigo('Indigo', Colors.indigo),
  violet('Violet', Color(0xFF8F00FF)),
  purple('Purple', Colors.purple),
  silver('Silver', Color(0xFF808080)),
  gold('Gold', Color(0xFFFFD700)),
  beige('Beige', Color(0xFFF5F5DC)),
  brown('Brown', Colors.brown),
  black('Black', Colors.black),
  white('White', Colors.white);

  const ColorLabel(this.label, this.color);
  final String label;
  final Color color;
}

class AppTheme {
  // 색상 변수 정의
  static const Color primaryColor = Color(0xFF414141); //
  static const Color secondaryColor = Color(0xa9a9a9a9); //
  static const Color errorColor = Color(0xFF8B0000); // 빨간색
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color buttonbackgroundColor = Colors.grey; // 연한 회색
  static const Color thirdColor = Color(0xFF665f4f); // 연한 회색
  static const Color textColor = Color(0xFF024E50); //
  static const double textfieldRadious = 10.0;

// 전역 테마 설정
  static ThemeData get mpTheme {
    return ThemeData(
      primaryColor: primaryColor, // 주요 색상
      scaffoldBackgroundColor: Colors.grey[100], // 화면 배경색
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[50], // 앱 바 배경색
        foregroundColor: secondaryColor, // 앱 바 아이콘과 텍스트 색상
        titleTextStyle: subtitleTextStyle,
      ),
      textTheme: TextTheme(
        bodyLarge:
            TextStyle(color: primaryColor, fontSize: 16), // bodyLarge 텍스트 스타일
        bodyMedium:
            TextStyle(color: primaryColor, fontSize: 14), // bodyMedium 텍스트 스타일
      ),
      colorScheme: ColorScheme.light(
        primary: Colors.grey, // 주요 색상
        secondary: Colors.grey[600]!, // 보조 색상
        surface: Colors.grey[50]!, // 표면 색상
      ),
      iconTheme: IconThemeData(color: secondaryColor), // 아이콘 색상

      tabBarTheme: TabBarTheme(
        labelPadding: EdgeInsets.symmetric(vertical: 0), // ✅ 상하 여백 조정
      ),

      inputDecorationTheme: InputDecorationTheme(
          // TextField 스타일
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(textfieldRadious),
            borderSide: BorderSide(
              color: secondaryColor,
              width: 1.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(textfieldRadious),
            borderSide: BorderSide(color: secondaryColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(textfieldRadious),
            borderSide: BorderSide(color: secondaryColor, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(textfieldRadious),
            borderSide: BorderSide(color: secondaryColor, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(textfieldRadious),
            borderSide: BorderSide(color: secondaryColor, width: 1.5),
          ),
          isDense: true, // 높이를 줄이는 옵션
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          errorStyle: errorTextStyle, // 에러 메시지 스타일 적용
          prefixIconColor: secondaryColor,
          labelStyle: textfieldStyle,
          hintStyle: bodyMedium.copyWith(color: Colors.grey[400])),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonbackgroundColor, // 버튼 배경색
          padding: EdgeInsets.symmetric(vertical: 15.0), // 버튼 내부 패딩
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(textfieldRadious), // 테두리 반경
          ),
          foregroundColor: Colors.white, // 텍스트 색상 설정
          textStyle: TextStyle(fontSize: 17.0),
        ),
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
    color: primaryColor, // 서브 텍스트 색상
  );

  static const TextStyle errorTextStyle = TextStyle(
    fontSize: 13,
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
    fontSize: 16,
    color: CupertinoColors.systemGrey,
  );

  // Display styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57.0,
    height: 64.0 / 57.0,
    fontWeight: FontWeight.w400, // regular
    letterSpacing: -0.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45.0,
    height: 52.0 / 45.0,
    fontWeight: FontWeight.w400, // regular
    letterSpacing: 0.0,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36.0,
    height: 44.0 / 36.0,
    fontWeight: FontWeight.w400, // regular
    letterSpacing: 0.0,
  );

  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32.0,
    height: 40.0 / 32.0,
    fontWeight: FontWeight.w400, // regular
    letterSpacing: 0.0,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28.0,
    height: 36.0 / 28.0,
    fontWeight: FontWeight.w400, // regular
    letterSpacing: 0.0,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24.0,
    height: 32.0 / 24.0,
    fontWeight: FontWeight.w400, // regular
    letterSpacing: 0.0,
  );

  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22.0,
    height: 28.0 / 22.0,
    fontWeight: FontWeight.w400, // regular
    letterSpacing: 0.0,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16.0,
    height: 24.0 / 16.0,
    fontWeight: FontWeight.w500, // medium
    letterSpacing: 0.15,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14.0,
    height: 20.0 / 14.0,
    fontWeight: FontWeight.w500, // medium
    letterSpacing: 0.1,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    height: 24.0 / 16.0,
    fontWeight: FontWeight.w400, // regular
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    height: 20.0 / 14.0,
    fontWeight: FontWeight.w400, // regular
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    height: 16.0 / 12.0,
    fontWeight: FontWeight.w400, // regular
    letterSpacing: 0.4,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14.0,
    height: 20.0 / 14.0,
    fontWeight: FontWeight.w500, // medium
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12.0,
    height: 16.0 / 12.0,
    fontWeight: FontWeight.w500, // medium
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11.0,
    height: 16.0 / 11.0,
    fontWeight: FontWeight.w500, // medium
    letterSpacing: 0.5,
  );

  static const EdgeInsets popupPadding = EdgeInsets.all(16); // 팝업 기본 패딩
}

// IconData getIconFromString(String iconName) {
//   // Map of string icon names to Icons
//   final iconMap = <String, IconData>{
//     'directions_bus': Icons.directions_bus_filled_outlined,
//     'restaurant': Icons.restaurant,
//     'hotel': Icons.hotel_outlined,
//   };

//   // Return IconData from the map or a default icon if not found
//   return iconMap[iconName] ?? Icons.help_outline;
// }
IconData getIconFromString(String iconName) {
  // `IconLabel`의 모든 값을 순회하여 해당 label과 일치하는 IconData를 반환
  for (var iconLabel in IconLabel.values) {
    if (iconLabel.label == iconName) {
      return iconLabel.icon;
    }
  }
  // 일치하는 값이 없을 경우 기본 아이콘 반환
  return Icons.help_outline;
}

Color hexToColor(String hexColor) {
  try {
    // '#' 기호 제거
    hexColor = hexColor.replaceAll('#', '');

    // 6자리 색상 문자열에 불투명도 추가
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor'; // 기본 불투명도 100%
    }

    // 8자리 색상 문자열을 Color로 변환
    return Color(int.parse('0x$hexColor'));
  } catch (e) {
    // 변환 실패 시 기본값으로 검정색 반환
    return Colors.black;
  }
}
