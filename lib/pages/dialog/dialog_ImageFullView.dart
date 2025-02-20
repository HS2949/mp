// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter/services.dart'; // 키보드 입력 감지
import 'package:url_launcher/url_launcher.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  FullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  int currentIndex = 0;
  Offset _startDragOffset = Offset.zero; // 드래그 시작 지점

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    currentIndex = widget.initialIndex;
  }

  /// 페이지 이동 함수
  void _goToPage(int index) {
    if (index >= 0 && index < widget.imageUrls.length) {
      _pageController.animateToPage(
        index,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        currentIndex = index;
      });
    }
  }

  /// 키보드 이벤트 감지 (ESC, Page Up/Down, 좌우 화살표)
  void _onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context); // ESC 키 → 창 닫기
      } else if (event.logicalKey == LogicalKeyboardKey.pageUp ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _goToPage(currentIndex - 1); // PageUp / ← → 이전 사진
      } else if (event.logicalKey == LogicalKeyboardKey.pageDown ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _goToPage(currentIndex + 1); // PageDown / → → 다음 사진
      }
    }
  }

  /// 우클릭 또는 길게 누르기 시 컨텍스트 메뉴 띄우기
  void _showContextMenu(BuildContext context, Offset globalPosition) async {
    // 메뉴를 화면에 표시하기 위해 showMenu 함수 사용
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'openInNewTab',
          child: Text('새 탭에서 이미지 열기'),
        ),
        PopupMenuItem<String>(
          value: 'copyImageUrl',
          child: Text('이미지 주소 복사'),
        ),
      ],
    );

    // 사용자가 메뉴 중 하나를 선택했을 때 처리할 로직
    switch (result) {
      case 'openInNewTab':
        // 1. 웹 브라우저나 외부 앱에서 이미지 URL 열기
        final url = widget.imageUrls[currentIndex];
        try {
          // url_launcher 사용
          // - LaunchMode.externalApplication: 외부 브라우저로 열기
          // - LaunchMode.inAppWebView: 앱 내부 WebView로 열기
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          } else {
            print("Could not launch $url");
          }
        } catch (e) {
          print("Error launching URL: $e");
        }
        break;

      case 'copyImageUrl':
        // 4. '이미지 주소 복사' → 간단히 URL 문자열을 클립보드에 복사
        Clipboard.setData(ClipboardData(text: widget.imageUrls[currentIndex]));
        print('이미지 주소 복사 완료');
        break;

      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: _onKey,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text(
            "${currentIndex + 1} / ${widget.imageUrls.length}",
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: GestureDetector(
          // **데스크톱/웹**: 우클릭(secondary tap)
          onSecondaryTapDown: (TapDownDetails details) {
            _showContextMenu(context, details.globalPosition);
          },
          // **모바일**: 길게 누르기
          onLongPressStart: (LongPressStartDetails details) {
            // 원치 않는 경우, if (_isMobile) { ... } 처럼 조건 분기
            _showContextMenu(context, details.globalPosition);
          },
          onHorizontalDragStart: (details) {
            _startDragOffset = details.globalPosition; // 드래그 시작 위치 저장
          },
          onHorizontalDragUpdate: (details) {
            double dx = details.globalPosition.dx - _startDragOffset.dx;
            if (dx > 50) {
              // 오른쪽으로 드래그 → 이전 사진
              _goToPage(currentIndex - 1);
              _startDragOffset = details.globalPosition;
            } else if (dx < -50) {
              // 왼쪽으로 드래그 → 다음 사진
              _goToPage(currentIndex + 1);
              _startDragOffset = details.globalPosition;
            }
          },
          child: PhotoViewGallery.builder(
            scrollPhysics: NeverScrollableScrollPhysics(), // 기본 스와이프 제거
            itemCount: widget.imageUrls.length,
            pageController: _pageController,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(widget.imageUrls[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.5,
              );
            },
            backgroundDecoration: BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
