import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/utils/fileViewer.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:url_launcher/url_launcher.dart';

/// value 값을 받아 4가지 경우에 따라 서로 다른 타입(문자열 또는 위젯)을 반환합니다.
dynamic formatValue(BuildContext context, String value) {
  final List<String> lines = value.trim().split('\n'); // 멀티라인 처리
  final List<dynamic> items = []; // String 또는 Widget을 담을 수 있음

  for (String line in lines) {
    String trimmed = line.trim();

    // 1. 숫자 처리: 숫자(콤마 포함) + 선택적 괄호가 있는 경우
    final RegExp numberWithTextRegExp = RegExp(r'^([\d,]+)(\s+[\S\s]+)?$');
    if (numberWithTextRegExp.hasMatch(trimmed)) {
      final Match match = numberWithTextRegExp.firstMatch(trimmed)!;
      String numberPart = match.group(1)!;
      String trailingText = match.group(2) ?? ''; // 뒤의 텍스트 (없으면 빈 문자열)

      String numberStr = numberPart.replaceAll(',', '');
      if (RegExp(r'^\d+$').hasMatch(numberStr)) {
        try {
          int number = int.parse(numberStr);
          String formattedNumber = NumberFormat('#,###').format(number);
          // 숫자 부분만 변환, 나머지는 그대로 추가
          items.add('$formattedNumber$trailingText');
          continue;
        } catch (e) {
          items.add(trimmed);
          continue;
        }
      }
    }

    // 2. firebasestorage의 PDF 파일 / 그림파일 처리
    if (trimmed.toLowerCase().contains('.pdf')) {
      final int bracketIndex = trimmed.lastIndexOf('[');

      // URL과 표시 텍스트 분리
      final String pdfUrl = bracketIndex != -1
          ? trimmed.substring(0, bracketIndex).trim()
          : trimmed;
      final String displayText = bracketIndex != -1
          ? trimmed
              .substring(bracketIndex)
              .replaceAll(RegExp(r'[\[\]]'), '')
              .trim()
          : urlFileName(pdfUrl);

      items.add(
        Tooltip(
          message: urlFileName(pdfUrl),
          child: Container(
            height: 30,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PDFViewerPage(url: pdfUrl),
                  ),
                );
              },
              child: Text(
                displayText,
                style: AppTheme.bodySmallTextStyle.copyWith(
                  fontSize: 13,
                  color: AppTheme.pdfFileColor,
                ),
              ),
            ),
          ),
        ),
      );
      continue;
    } else {
      if (trimmed.contains('firebasestorage')) {
        // 정규 표현식을 사용하여 "[@숫자]" 패턴을 찾습니다. 앞뒤 공백 허용
        final RegExp regExp = RegExp(r'\s*\[@(\d+)\]\s*$');
        double maxHeight = 300; // 기본 최대 높이 값

        if (regExp.hasMatch(trimmed)) {
          final match = regExp.firstMatch(trimmed);
          if (match != null) {
            // 그룹 1에서 숫자 값을 추출합니다.
            maxHeight = double.parse(match.group(1)!);
            // 태그 부분과 태그 앞뒤의 공백 제거 후 다시 trim()
            trimmed = trimmed.replaceAll(regExp, '').trim();
          }
        }

        items.add(
          GestureDetector(
            onTap: () => _launchURL(context, trimmed), // 클릭 시 브라우저로 URL 오픈
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: trimmed));
              showOverlayMessage(context, "그림파일 주소 복사");
            },
            child: Tooltip(
              message:
                  '[${filenameStoragePath(trimmed)}]\n클릭 : 새창에서 열기\n길게 누르기 : 그림파일 주소 클립보드 복사',
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: maxHeight, // 동적으로 설정된 최대 높이 사용
                ),
                child: CachedNetworkImage(
                  imageUrl: trimmed,
                  fit: BoxFit.contain,
                  fadeInDuration: const Duration(milliseconds: 500),
                  placeholder: (context, url) => Image.asset(
                    'assets/images/loading.gif',
                    width: 50,
                    fit: BoxFit.contain,
                  ),
                  errorWidget: (context, url, error) => const Text(
                    '이미지 로드 실패',
                    style: AppTheme.textErrorTextStyle,
                  ),
                ),
              ),
            ),
          ),
        );
        continue;
      }
    }

    // 3. 전화번호 처리
// 전화번호 패턴: 2~4자리 숫자, 하이픈, 3~4자리 숫자, 하이픈, 4자리 숫자
    final RegExp phonePattern = RegExp(r'\b(\d{2,4}-\d{3,4}-\d{4})\b');
    final Iterable<Match> phoneMatches = phonePattern.allMatches(trimmed);

    if (phoneMatches.isNotEmpty) {
      int currentIndex = 0;
      List<Widget> rowChildren = [];

      for (final match in phoneMatches) {
        // 전화번호 앞의 일반 텍스트 추가
        if (match.start > currentIndex) {
          rowChildren.add(
            Text(
              trimmed.substring(currentIndex, match.start),
              style: AppTheme.bodySmallTextStyle,
            ),
          );
        }

        final String phoneNumber = match.group(0)!;

        // 전화번호 버튼 추가
        rowChildren.add(
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: phoneNumber));
              showOverlayMessage(context, "전화번호 복사됨");
            },
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () async {
                final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
                if (await canLaunchUrl(telUri)) {
                  await launchUrl(telUri);
                } else {
                  print('Could not launch $phoneNumber');
                }
              },
              child: Text(
                phoneNumber,
                style: AppTheme.bodySmallTextStyle.copyWith(
                  fontSize: 13,
                  color: AppTheme.text2Color,
                ),
              ),
            ),
          ),
        );

        currentIndex = match.end;
      }

      // 전화번호 이후 남은 텍스트 추가
      if (currentIndex < trimmed.length) {
        rowChildren.add(
          SelectableText(
            trimmed.substring(currentIndex),
            style: AppTheme.bodySmallTextStyle,
          ),
        );
      }

      items.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: rowChildren,
        ),
      );
      continue;
    }

    // 4. 홈페이지 링크 처리 (URL과 표시 텍스트를 분리)
    final RegExp linkPattern = RegExp(r'^(https?:\/\/|www\.)[^\s\[\]]+');
    final Match? linkMatch = linkPattern.firstMatch(trimmed);

    if (linkMatch != null) {
      final String urlPart = linkMatch.group(0)!;
      final RegExp displayTextPattern = RegExp(r'\[(.*?)\]');
      final Match? displayMatch = displayTextPattern.firstMatch(trimmed);
      final String displayText =
          displayMatch != null ? displayMatch.group(1)! : urlPart;

      final String remainingText = trimmed
          .replaceFirst(urlPart, '')
          .replaceFirst(displayMatch?.group(0) ?? '', '')
          .trim();

      String href = urlPart.startsWith('www.') ? 'http://$urlPart' : urlPart;

      items.add(Tooltip(
        message: href,
        child: Container(
          height: 30,
          child: TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () async {
              final Uri url = Uri.parse(href);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                print('Could not launch $href');
              }
            },
            child: Text(
              remainingText.isNotEmpty ? '[링크]' : '$displayText',
              style: AppTheme.bodySmallTextStyle.copyWith(
                fontSize: 13,
                color: AppTheme.text9Color,
              ),
            ),
          ),
        ),
      ));
      continue;
    }

    // 5. 그 외의 경우: 일반 텍스트 그대로 문자열로 리턴
    items.add(trimmed);
  }

  // 모든 항목이 String인지 확인
  final bool allStrings = items.every((item) => item is String);

  if (allStrings) {
    // 단일 항목이면 그대로, 여러 항목이면 줄바꿈하여 하나의 문자열로 리턴
    return items.length == 1 ? items.first : items.join("\n");
  } else {
    // 위젯이 포함되어 있는 경우, String은 Text 위젯으로 감싸서 Column으로 반환
    final List<Widget> widgets = items.map<Widget>((item) {
      if (item is Widget) {
        return item;
      } else if (item is String) {
        return SelectableText(item, style: AppTheme.bodySmallTextStyle);
      }
      return const SizedBox.shrink();
    }).toList();

    return widgets.length == 1
        ? widgets.first
        : Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widgets,
          );
  }
}

/// 이미지 URL을 브라우저에서 열기 위한 함수
Future<void> _launchURL(BuildContext context, String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    // throw 'Could not launch $url';
    showOverlayMessage(context, "Could not launch \n$url");
  }
}

String filenameStoragePath(String url) {
  // "/o/" 이후부터 "?" 이전까지 경로 추출
  RegExp regExp = RegExp(r'/o/([^?]*)');
  Match? match = regExp.firstMatch(url);

  if (match != null && match.groupCount > 0) {
    String fullPath = Uri.decodeComponent(match.group(1)!); // URL 디코딩
    return fullPath.split('/').last; // 경로에서 마지막 부분(파일명)만 추출
  }
  return '경로 없음';
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
  TextEditingController? controller,
  bool doGestureDetector = true,
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

  if (doGestureDetector) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: text));
        showOverlayMessage(context, "클립보드 복사");
      },
      child: child,
    );
  } else {
    return child;
  }
}
