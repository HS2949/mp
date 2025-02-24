import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:url_launcher/url_launcher.dart';

/// value 값을 받아 4가지 경우에 따라 서로 다른 타입(문자열 또는 위젯)을 반환합니다.
dynamic formatValue(BuildContext context, String value) {
  final List<String> lines = value.trim().split('\n'); // 멀티라인 처리
  final List<dynamic> items = []; // String 또는 Widget을 담을 수 있음

  for (String line in lines) {
    final String trimmed = line.trim();

    // 1. 숫자 처리: 숫자(콤마 포함) + 선택적 괄호가 있는 경우
    final RegExp numberRegExp = RegExp(r'^([\d,]+)(\s*\(.*\))?$');
    if (numberRegExp.hasMatch(trimmed)) {
      final Match? match = numberRegExp.firstMatch(trimmed);
      if (match != null) {
        String numberPart = match.group(1)!;
        String? suffix = match.group(2);
        String numberStr = numberPart.replaceAll(',', '');
        if (RegExp(r'^\d+$').hasMatch(numberStr)) {
          try {
            int number = int.parse(numberStr);
            String formattedNumber = NumberFormat('#,###').format(number);
            // 문자열만 리턴
            items.add(formattedNumber + (suffix ?? ''));
            continue;
          } catch (e) {
            items.add(trimmed);
            continue;
          }
        }
      }
    }

    // 2. Firestorage 링크 처리: 링크에 "firebasestorage"라는 단어가 포함되면 이미지로 간주
    if (trimmed.contains('firebasestorage')) {
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
            child: FadeInImage.assetNetwork(
              placeholder: 'assets/images/loading.gif', // 로딩 중 보여줄 이미지
              placeholderScale: 2,
              placeholderFit: BoxFit.none, // 플레이스홀더의 크기 맞춤 방식 설정
              image: trimmed,
              fit: BoxFit.cover,
              fadeInDuration:
                  Duration(milliseconds: 500), // 페이드인 지속 시간 (기본값 700ms)
              imageErrorBuilder: (context, error, stackTrace) {
                return const Text('이미지 로드 실패',
                    style: AppTheme.textErrorTextStyle);
              },
            ),
          ),
        ),
      );
      continue;
    }

    // 3. 홈페이지 링크 처리 (URL과 표시 텍스트를 분리)
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
          .replaceFirst(displayMatch?.group(0) ?? '', '');

      String href = urlPart.startsWith('www.') ? 'http://$urlPart' : urlPart;

      items.add(Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Tooltip(
            message: href,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
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
                remainingText.isNotEmpty ? '[링크]' : displayText,
                style: AppTheme.bodySmallTextStyle.copyWith(
                  fontSize: 13,
                  color: AppTheme.text9Color,
                ),
              ),
            ),
          ),
        ],
      ));
      continue;
    }

    // 4. 그 외의 경우: 일반 텍스트 그대로 문자열로 리턴
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
        return Text(item, style: AppTheme.bodySmallTextStyle);
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
