import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:url_launcher/url_launcher.dart';

/// value 값을 받아 4가지 경우에 따라 서로 다른 타입(문자열 또는 위젯)을 반환합니다.
dynamic formatValue(String value) {
  final List<String> lines = value.trim().split('\n'); // 멀티라인 처리
  List<Widget> widgets = [];

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
            widgets.add(Text(formattedNumber + (suffix ?? ''),
                style: AppTheme.bodySmallTextStyle));
            continue;
          } catch (e) {
            widgets.add(Text(trimmed, style: AppTheme.bodySmallTextStyle));
            continue;
          }
        }
      }
    }

    // 2. Firestorage 링크 처리: 링크에 "firebasestorage"라는 단어가 포함되면 이미지로 간주
    if (trimmed.contains('firebasestorage')) {
      widgets.add(
        GestureDetector(
          onTap: () => _launchURL(trimmed), // 클릭 시 브라우저로 URL 오픈
          child: Tooltip(
            message: '새창에서 열기  [${filenameStoragePath(trimmed)}]',
            child: FadeInImage.assetNetwork(
              placeholder: 'assets/images/loading.gif', // 로딩 중 보여줄 이미지
              placeholderScale: 2,
              placeholderFit: BoxFit.none, // 플레이스홀더의 크기 맞춤 방식 설정
              image: trimmed,
              fit: BoxFit.cover,
              fadeInDuration:
                  Duration(milliseconds: 500), // 페이드인 지속 시간 (기본값 700ms)
              imageErrorBuilder: (context, error, stackTrace) {
                return const Text('이미지 로드 실패');
              },
            ),
          ),
        ),
      );
      continue;
    }

    // 3. 홈페이지 링크 처리 (URL과 표시 텍스트를 분리)
    final RegExp linkPattern = RegExp(r'^(https?:\/\/|www\.)[^\s\[\]]+');
    final Match? match = linkPattern.firstMatch(trimmed);

    if (match != null) {
      final String urlPart = match.group(0)!;
      final RegExp displayTextPattern = RegExp(r'\[(.*?)\]');
      final Match? displayMatch = displayTextPattern.firstMatch(trimmed);
      final String displayText =
          displayMatch != null ? displayMatch.group(1)! : urlPart;

      final String remainingText = trimmed
          .replaceFirst(match.group(0)!, '')
          .replaceFirst(displayMatch?.group(0) ?? '', '');

      String href = urlPart.startsWith('www.') ? 'http://$urlPart' : urlPart;

      widgets.add(Row(
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
                displayText,
                style: AppTheme.bodySmallTextStyle
                    .copyWith(fontSize: 13, color: AppTheme.text9Color),
              ),
            ),
          ),
          if (remainingText.isNotEmpty)
            Flexible(
              child: Text(
                remainingText,
                style: AppTheme.bodySmallTextStyle.copyWith(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ));
      continue;
    }

    // 4. 그 외의 경우: 일반 텍스트 그대로 반환
    widgets.add(Text(trimmed, style: AppTheme.bodySmallTextStyle));
  }

  // 단일 항목이면 직접 반환, 여러 항목이면 Column으로 감싸기
  return widgets.length == 1
      ? widgets.first
      : Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widgets);
}

/// 이미지 URL을 브라우저에서 열기 위한 함수
Future<void> _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Could not launch $url';
  }
}

String filenameStoragePath(String url) {
  // "/o/" 이후부터 "?" 이전까지 경로 추출
  RegExp regExp = RegExp(r'/o/([^?]*)');
  Match? match = regExp.firstMatch(url);

  if (match != null && match.groupCount > 0) {
    return Uri.decodeComponent(match.group(1)!); // URL 디코딩
  }
  return '경로 없음';
}
