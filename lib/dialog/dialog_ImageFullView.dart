// ignore_for_file: deprecated_member_use

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

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
  Offset _startDragOffset = Offset.zero;
  int? _imageWidth;
  int? _imageHeight;
  int? _fileSize;
  bool _isLoading = false; // 데이터 로딩 상태 관리

  // precache를 didChangeDependencies에서 한 번만 실행하기 위한 플래그
  bool _didPrecache = false;

  // 각 이미지 페이지별 PhotoViewController 저장
  final Map<int, PhotoViewController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    currentIndex = widget.initialIndex;
    _loadImageData(widget.imageUrls[currentIndex]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // context가 트리에 완전히 연결된 뒤에 한 번만 미리 캐싱
    if (!_didPrecache) {
      _precacheNextImage();
      _didPrecache = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    // 생성한 컨트롤러들 모두 dispose 처리
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
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
        _isLoading = true;
        _imageWidth = null;
        _imageHeight = null;
        _fileSize = null;
      });

      _loadImageData(widget.imageUrls[index]);
      _precacheNextImage();
    }
  }

  /// 키보드 이벤트 감지 (ESC, Page Up/Down, 좌우 화살표)
  void _onKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
      } else if (event.logicalKey == LogicalKeyboardKey.pageUp ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _goToPage(currentIndex - 1);
      } else if (event.logicalKey == LogicalKeyboardKey.pageDown ||
          event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _goToPage(currentIndex + 1);
      }
    }
  }

  /// 이미지 해상도 가져오기
  void _getImageSize(String imageUrl) {
    final imageProvider = NetworkImage(imageUrl);
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((ImageInfo info, bool _) {
      if (mounted) {
        setState(() {
          _imageWidth = info.image.width;
          _imageHeight = info.image.height;
          _checkLoadingStatus();
        });
      }
    }));
  }

  /// 파일 크기 가져오기 (HEAD 요청)
  Future<void> _getImageFileSize(String imageUrl) async {
    try {
      final response = await http.head(Uri.parse(imageUrl));
      if (response.statusCode == 200 &&
          response.headers.containsKey('content-length')) {
        if (mounted) {
          setState(() {
            _fileSize = int.parse(response.headers['content-length']!);
            _checkLoadingStatus();
          });
        }
      }
    } catch (e) {
      print("파일 크기 가져오기 오류: $e");
    }
  }

  /// 로딩 상태 확인 (모든 데이터가 로드되면 `_isLoading`을 `false`로 설정)
  void _checkLoadingStatus() {
    if (mounted) {
      setState(() {
        _isLoading =
            (_imageWidth == null || _imageHeight == null || _fileSize == null);
      });
    }
  }

  /// 이미지 정보 로드 (해상도 + 파일 크기)
  void _loadImageData(String imageUrl) {
    _getImageSize(imageUrl);
    _getImageFileSize(imageUrl);
  }

  /// 다음 이미지 미리 캐싱
  void _precacheNextImage() {
    if (currentIndex + 1 < widget.imageUrls.length) {
      precacheImage(
        NetworkImage(widget.imageUrls[currentIndex + 1]),
        context,
      );
    }
  }

  String _getFileName(String imageUrl) {
    Uri uri = Uri.parse(imageUrl);
    String fileNameWithExtension =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';

    // 경로 제거 후 순수한 파일명만 반환
    fileNameWithExtension = fileNameWithExtension.split('/').last;

    // 쿼리 파라미터(?)와 프래그먼트(#) 제거
    fileNameWithExtension =
        fileNameWithExtension.split('?').first.split('#').first;

    return fileNameWithExtension;
  }

  /// 우클릭 또는 길게 누르기 시 컨텍스트 메뉴 띄우기
  void _showContextMenu(BuildContext context, Offset globalPosition) async {
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

    switch (result) {
      case 'openInNewTab':
        final url = widget.imageUrls[currentIndex];
        try {
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
        Clipboard.setData(ClipboardData(text: widget.imageUrls[currentIndex]));
        print('이미지 주소 복사 완료');
        break;
      default:
        break;
    }
  }

  /// 마우스 휠 이벤트 처리: 현재 페이지의 PhotoViewController를 통해 scale 조정
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final controller = _controllers[currentIndex];
      if (controller != null) {
        // 현재 scale 값에 스크롤 델타를 반영하여 새로운 scale 계산
        final double currentScale = controller.value.scale ?? 1.0;
        double zoomStep = -event.scrollDelta.dy * 0.001;
        double newScale = (currentScale + zoomStep).clamp(0.5, 3.0);
        // scale 값을 직접 업데이트
        controller.scale = newScale;
      }
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
          title: Wrap(
            spacing: 50,
            children: [
              Text(
                "${currentIndex + 1} / ${widget.imageUrls.length}",
                style: TextStyle(color: Colors.white),
              ),
              Text(
                _isLoading
                    ? '로딩 중...'
                    : '${_getFileName(widget.imageUrls[currentIndex])}',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              Text(
                _isLoading
                    ? ''
                    : '(크기: ${_imageWidth ?? "?"} x ${_imageHeight ?? "?"}, '
                        '용량: ${_fileSize != null ? (_fileSize! / 1024).toStringAsFixed(2) + " KB" : "?"})',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        // Listener로 마우스 휠 이벤트 처리
        body: Listener(
          onPointerSignal: _handlePointerSignal,
          child: GestureDetector(
            onSecondaryTapDown: (TapDownDetails details) {
              _showContextMenu(context, details.globalPosition);
            },
            // 모바일: 길게 누르기
            onLongPressStart: (LongPressStartDetails details) {
              _showContextMenu(context, details.globalPosition);
            },
            onHorizontalDragStart: (details) {
              _startDragOffset = details.globalPosition;
            },
            onHorizontalDragUpdate: (details) {
              double dx = details.globalPosition.dx - _startDragOffset.dx;
              if (dx > 80) {
                _goToPage(currentIndex - 1);
                _startDragOffset = details.globalPosition;
              } else if (dx < -80) {
                _goToPage(currentIndex + 1);
                _startDragOffset = details.globalPosition;
              }
            },
            child: PhotoViewGallery.builder(
              scrollPhysics: NeverScrollableScrollPhysics(),
              itemCount: widget.imageUrls.length,
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                  _isLoading = true;
                  _imageWidth = null;
                  _imageHeight = null;
                  _fileSize = null;
                });
                _loadImageData(widget.imageUrls[index]);
                _precacheNextImage();
              },
              builder: (context, index) {
                // 각 페이지별로 PhotoViewController 생성 및 저장
                final controller = _controllers[index] ??= PhotoViewController(
                  initialScale: 1.0,
                );
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(widget.imageUrls[index]),
                  controller: controller,
                  minScale: PhotoViewComputedScale.contained, // 최소 배율
                  maxScale: 3.0, // 최대 확대 배율
                  initialScale: PhotoViewComputedScale.contained, // 초기 배율
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              color: Colors.white, size: 50),
                          SizedBox(height: 10),
                          Text("이미지를 불러올 수 없습니다.",
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    );
                  },
                );
              },
              backgroundDecoration: BoxDecoration(color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}
