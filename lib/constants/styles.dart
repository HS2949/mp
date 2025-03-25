// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const double narrowScreenWidthThreshold = 450;

const double mediumWidthBreakpoint = 1000 * 0.8;
const double largeWidthBreakpoint = 1500 * 0.8;

const double transitionLength = 500;

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
  static const Color backgroundColor = Color(0xFFF5F5F5); //grey[100]
  static const Color appbarbackgroundColor = Color(0xFFFAFAFA); // grey[50]
  static const Color textLabelColor =
      Color(0xFF8E8E93); // CupertinoColors.systemGrey
  static const Color textHintColor = Color(0xFFBDBDBD); //grey[400]
  static const Color errorColor = Color(0xFF8B0000); // 빨간색
  static const Color itemListColor = Color.fromARGB(255, 128, 46, 46);
  static const Color itemList0Color = Color.fromARGB(122, 128, 46, 46);
  static const Color pdfFileColor = Color.fromARGB(150, 255, 67, 129);
  static const Color buttonbackgroundColor = Colors.grey; // 연한 회색
  static const Color buttonlightbackgroundColor =
      Color(0xFFE0E0E0); // grey[300]

  static const Color thirdColor = Color(0xFF665f4f); // 연한 회색
  static const Color text2Color = Color(0xFF024E50); //
  static const Color textStrongColor = CupertinoColors.systemYellow; //
  static const Color text3Color = CupertinoColors.systemPurple; //
  static const Color text4Color = Color(0xFF002060); //
  static const Color text5Color = Color(0xFF7030A0); //
  static const Color text6Color = Color(0xFFFF6699); //
  static const Color text7Color = Color(0xFF007635); //
  static const Color text8Color = Color(0xFF30859C); //
  static const Color text9Color = Color(0xFF35AFAF); //
  static final Color toolColor = CupertinoColors.systemYellow
      .withOpacity(0.3); //Color.fromARGB(255, 240, 237, 107);
  static const double textfieldRadious = 10.0;

// 전역 테마 설정
  static ThemeData get mpTheme {
    return ThemeData(
      //  fontFamily: '맑은글꼴',
      //fontFamily: 'NotoSans', // 원하는 글꼴 설정
      primaryColor: primaryColor, // 주요 색상
      scaffoldBackgroundColor: backgroundColor, // 화면 배경색
      appBarTheme: AppBarTheme(
        backgroundColor: appbarbackgroundColor, // 앱 바 배경색
        foregroundColor: secondaryColor, // 앱 바 아이콘과 텍스트 색상
        titleTextStyle: appbarTitleTextStyle,
      ),
      colorScheme: ColorScheme.light(
        primary: primaryColor, // 주요 색상
        secondary: secondaryColor, // 보조 색상
        surface: appbarbackgroundColor, // 표면 색상 // 카드와 네비게이션레일 색색
      ),
      iconTheme: IconThemeData(color: secondaryColor), // 아이콘 색상
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: textStrongColor.withOpacity(0.1), // 선택된 텍스트의 배경색
        cursorColor: text4Color, // 커서 색상
        selectionHandleColor: text9Color, // 선택 핸들의 색상
      ),
      tabBarTheme: TabBarTheme(
        labelPadding: EdgeInsets.symmetric(vertical: 0), // 상하 여백 조정
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
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        prefixIconColor: secondaryColor,

        labelStyle: textLabelStyle, // 라벨 메시지 스타일 적용
        hintStyle: textHintTextStyle, // 힌트 메시지 스타일 적용
        errorStyle: textErrorTextStyle, // 에러 메시지 스타일 적용

        filled: true,
        fillColor: appbarbackgroundColor,
      ),

      // ========================================================  카드 테마
      textTheme: TextTheme(
        bodyMedium:
            TextStyle(overflow: TextOverflow.ellipsis), // 기본 overflow 설정
      ),
      cardTheme: CardTheme(
        // ========================================================  카드 테마
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // 라운드 제거
        ),
      ),
      // ========================================================  SnackBar 테마
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryColor.withOpacity(0.8), // 🔹 배경 색상
        contentTextStyle:
            textLabelStyle.copyWith(color: backgroundColor), // 🔹 텍스트 색상
        actionTextColor: buttonbackgroundColor, // 🔹 액션 버튼 텍스트 색상
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // 🔹 둥근 모서리
        ),
        behavior: SnackBarBehavior.floating, // 🔹 떠 있는 스낵바 스타일
      ),
      // ========================================================  Tooltip 테마
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.4), // 배경색 변경
          borderRadius: BorderRadius.circular(8), // 모서리 둥글게
        ),
        textStyle: TextStyle(
          color: Colors.white, // 글자 색상 변경
          fontSize: 11,
        ),
        waitDuration: Duration(milliseconds: 100), // 툴팁 표시까지 걸리는 시간
        showDuration: Duration(seconds: 2), // 툴팁이 유지되는 시간
      ),
      // ========================================================  ElevatedButton 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          animationDuration: Duration(milliseconds: 200), // 애니메이션 지속 시간
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.pressed)) {
              return AppTheme.backgroundColor; // 클릭 시 색상
            }
            if (states.contains(MaterialState.hovered)) {
              return AppTheme.buttonbackgroundColor; // 마우스 오버 시 색상
            }
            return AppTheme.buttonlightbackgroundColor; // 기본 색상
          }),
          foregroundColor: MaterialStateProperty.all(Colors.white), // 텍스트 색상
          padding: MaterialStateProperty.all(
              EdgeInsets.symmetric(vertical: 0.0)), // 내부 패딩
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(textfieldRadious), // 테두리 반경
            ),
          ),
          textStyle: MaterialStateProperty.all(buttonTextTextStyle), // 텍스트 스타일
          overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
            if (states.contains(MaterialState.hovered)) {
              return AppTheme.buttonbackgroundColor
                  .withOpacity(0.5); // 마우스 오버 시 효과
            }
            return null;
          }),
        ),
      ),
    );
  }

// Theme.of(context).textTheme.titleMedium;

  // 텍스트 스타일

  static const TextStyle appbarTitleTextStyle = TextStyle(
      fontSize: 17.0, // regular
      // height: 1.5, // regular
      fontWeight: FontWeight.w500, // regular
      // letterSpacing: 0.25,
      color: primaryColor);

  static const TextStyle bodyLargeTextStyle =
      TextStyle(fontSize: 18.0, color: primaryColor);

  static const TextStyle bodyMediumTextStyle =
      TextStyle(fontSize: 16.0, color: primaryColor);

  static const TextStyle bodySmallTextStyle =
      TextStyle(fontSize: 14.0, color: primaryColor);

  static const TextStyle titleLargeTextStyle =
      TextStyle(fontSize: 22.0, color: primaryColor);

  static const TextStyle titleMediumTextStyle = TextStyle(
      fontSize: 16.0, fontWeight: FontWeight.bold, color: primaryColor);

  static const TextStyle titleSmallTextStyle = TextStyle(
      fontSize: 14.0, fontWeight: FontWeight.bold, color: primaryColor);

  static const TextStyle textLabelStyle = TextStyle(
    fontSize: 14,
    color: textLabelColor,
  );

  static TextStyle textHintTextStyle =
      TextStyle(fontSize: 14.0, color: textHintColor);

  static const TextStyle textErrorTextStyle = TextStyle(
    fontSize: 13,
    color: errorColor, // 서브 텍스트 색상
  );
  static const TextStyle buttonTextTextStyle =
      TextStyle(fontSize: 16, color: Colors.white);

  static const TextStyle textCGreyStyle = TextStyle(
    fontSize: 16,
    color: CupertinoColors.systemGrey,
  );

  static TextStyle fieldLabelTextStyle = TextStyle(
    fontSize: 14, // 라벨 텍스트 크기 조정
    fontWeight: FontWeight.bold, // 라벨 텍스트 굵기
    color: AppTheme.text4Color, // 라벨 텍스트 색상
  );

  static TextStyle tagTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textHintColor, // 서브 텍스트 색상
  );
  //=========================
// fontWeight: FontWeight.bold,
  // static const TextStyle keyTextStyle = TextStyle(
  //   fontSize: 13, // 글자 크기
  //   fontWeight: FontWeight.w200, // 글자 두께
  //   color: Color.fromARGB(255, 0, 0, 0), // 글자 색상
  // );

  // static const TextStyle valueTextStyle = TextStyle(
  //   fontSize: 13, // 글자 크기
  //   fontWeight: FontWeight.w200, // 글자 두께
  //   color: Color.fromARGB(255, 19, 117, 202), // 글자 색상
  // );

  // static const TextStyle titleTextStyle = TextStyle(
  //   fontSize: 20,
  //   fontWeight: FontWeight.bold,
  //   color: CupertinoColors.black, // 기본 텍스트 색상
  // );

  // static const TextStyle subtitleTextStyle = TextStyle(
  //   fontSize: 16,
  //   fontWeight: FontWeight.w400,
  //   color: primaryColor, // 서브 텍스트 색상
  // );

  // // 팝업 스타일
  // static const TextStyle popupTitleStyle = TextStyle(
  //   fontSize: 18,
  //   fontWeight: FontWeight.bold,
  //   color: CupertinoColors.activeBlue, // 팝업 제목 색상
  // );

  // static const TextStyle popupMessageStyle = TextStyle(
  //   fontSize: 16,
  //   color: CupertinoColors.systemGrey,
  // );

  // static const TextStyle bodyMedium = TextStyle(
  //     fontSize: 14.0,
  //     height: 20.0 / 14.0,
  //     fontWeight: FontWeight.w400, // regular
  //     letterSpacing: 0.25,
  //     color: primaryColor);

  // // Display styles
  // static const TextStyle displayLarge = TextStyle(
  //   fontSize: 57.0,
  //   height: 64.0 / 57.0,
  //   fontWeight: FontWeight.w400, // regular
  //   letterSpacing: -0.25,
  // );

  // static const TextStyle displayMedium = TextStyle(
  //   fontSize: 45.0,
  //   height: 52.0 / 45.0,
  //   fontWeight: FontWeight.w400, // regular
  //   letterSpacing: 0.0,
  // );

  // static const TextStyle displaySmall = TextStyle(
  //   fontSize: 36.0,
  //   height: 44.0 / 36.0,
  //   fontWeight: FontWeight.w400, // regular
  //   letterSpacing: 0.0,
  // );

  // // Headline styles
  // static const TextStyle headlineLarge = TextStyle(
  //   fontSize: 32.0,
  //   height: 40.0 / 32.0,
  //   fontWeight: FontWeight.w400, // regular
  //   letterSpacing: 0.0,
  // );

  // static const TextStyle headlineMedium = TextStyle(
  //   fontSize: 28.0,
  //   height: 36.0 / 28.0,
  //   fontWeight: FontWeight.w400, // regular
  //   letterSpacing: 0.0,
  // );

  // static const TextStyle headlineSmall = TextStyle(
  //   fontSize: 24.0,
  //   height: 32.0 / 24.0,
  //   fontWeight: FontWeight.w400, // regular
  //   letterSpacing: 0.0,
  // );

  // // Title styles
  // static const TextStyle titleLarge = TextStyle(
  //   fontSize: 22.0,
  //   height: 28.0 / 22.0,
  //   fontWeight: FontWeight.w400, // regular
  //   letterSpacing: 0.0,
  // );

  // static const TextStyle titleMedium = TextStyle(
  //   fontSize: 16.0,
  //   height: 24.0 / 16.0,
  //   fontWeight: FontWeight.w500, // medium
  //   letterSpacing: 0.15,
  // );

  // static const TextStyle titleSmall = TextStyle(
  //   fontSize: 14.0,
  //   height: 20.0 / 14.0,
  //   fontWeight: FontWeight.w500, // medium
  //   letterSpacing: 0.1,
  // );

  // // Body styles
  // static const TextStyle bodyLarge = TextStyle(
  //   fontSize: 16.0,
  //   height: 24.0 / 16.0,
  //   fontWeight: FontWeight.w400, // regular
  //   letterSpacing: 0.5,
  // );

  // static const TextStyle bodyMedium = TextStyle(
  //   fontSize: 14.0,
  //   height: 20.0 / 14.0,
  //   fontWeight: FontWeight.w400, // regular
  //   letterSpacing: 0.25,
  // );

  // static const TextStyle bodySmall = TextStyle(
  //   fontSize: 12.0,
  //   height: 16.0 / 12.0,
  //   fontWeight: FontWeight.w400, // regular
  //   letterSpacing: 0.4,
  // );

  // // Label styles
  // static const TextStyle labelLarge = TextStyle(
  //   fontSize: 14.0,
  //   height: 20.0 / 14.0,
  //   fontWeight: FontWeight.w500, // medium
  //   letterSpacing: 0.1,
  // );

  // static const TextStyle labelMedium = TextStyle(
  //   fontSize: 12.0,
  //   height: 16.0 / 12.0,
  //   fontWeight: FontWeight.w500, // medium
  //   letterSpacing: 0.5,
  // );

  // static const TextStyle labelSmall = TextStyle(
  //   fontSize: 11.0,
  //   height: 16.0 / 11.0,
  //   fontWeight: FontWeight.w500, // medium
  //   letterSpacing: 0.5,
  // );

  static const EdgeInsets popupPadding = EdgeInsets.all(16); // 팝업 기본 패딩
}

// ✅ 커스텀 ScrollBehavior를 정의하여 앱 전체에 적용
class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return BouncingScrollPhysics(); // 모든 스크롤이 바운싱 효과를 가지도록 설정
  }
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
