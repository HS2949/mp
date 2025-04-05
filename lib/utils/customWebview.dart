import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
// Android용 웹뷰 패키지
import 'package:webview_flutter/webview_flutter.dart';
// Windows용 웹뷰 패키지
import 'package:webview_windows/webview_windows.dart';

class CustomWebViewWidget extends StatefulWidget {
  final String url;
  final double width;
  final double height;
  final bool isFit;

  /// 웹뷰 전체 좌표에서 보여주고 싶은 영역 (예: Rect.fromLTWH(0, 260, 800, 730))
  final Rect? cropRect;

  /// 웹뷰 내부 스크롤을 비활성화할지 여부
  final bool disableScroll;

  const CustomWebViewWidget({
    Key? key,
    required this.url,
    required this.width,
    required this.height,
    required this.isFit,
    this.cropRect,
    this.disableScroll = false,
  }) : super(key: key);

  @override
  State<CustomWebViewWidget> createState() => _CustomWebViewWidgetState();
}

class _CustomWebViewWidgetState extends State<CustomWebViewWidget> {
  // Android 전용 컨트롤러
  late final WebViewController _androidController;
  // Windows 전용 컨트롤러
  WebviewController? _windowsController;
  bool _windowsInitialized = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _androidController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) {
              if (widget.disableScroll) {
                _androidController.runJavaScript(
                    "document.documentElement.style.overflow = 'hidden';");
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url));
      if (widget.isFit) {
        _androidController.runJavaScript("""
          if (!document.querySelector('meta[name=viewport]')) {
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=${widget.width}, initial-scale=1.0';
            document.getElementsByTagName('head')[0].appendChild(meta);
          }
        """);
      }
    } else if (Platform.isWindows) {
      _initWindowsWebView();
    }
  }

  Future<void> _initWindowsWebView() async {
    final controller = WebviewController();
    await controller.initialize();
    await controller.loadUrl(widget.url);
    if (widget.disableScroll) {
      await controller
          .executeScript("document.documentElement.style.overflow = 'hidden';");
    }
    if (widget.isFit) {
      await controller.executeScript("""
        if (!document.querySelector('meta[name=viewport]')) {
          var meta = document.createElement('meta');
          meta.name = 'viewport';
          meta.content = 'width=${widget.width}, initial-scale=1.0';
          document.getElementsByTagName('head')[0].appendChild(meta);
        }
      """);
    }
    setState(() {
      _windowsController = controller;
      _windowsInitialized = true;
    });
  }

  // 뒤로 가기 함수
  Future<void> _goBack() async {
    if (Platform.isAndroid) {
      if (await _androidController.canGoBack()) {
        _androidController.goBack();
      }
    } else if (Platform.isWindows && _windowsController != null) {
      try {
        await _windowsController!.goBack();
      } catch (e) {
        debugPrint("Windows goBack error: $e");
      }
    }
  }

  // 앞으로 가기 함수
  Future<void> _goForward() async {
    if (Platform.isAndroid) {
      if (await _androidController.canGoForward()) {
        _androidController.goForward();
      }
    } else if (Platform.isWindows && _windowsController != null) {
      try {
        await _windowsController!.goForward();
      } catch (e) {
        debugPrint("Windows goForward error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget webView;

    if (Platform.isWindows) {
      if (!_windowsInitialized) {
        webView = const Center(child: CircularProgressIndicator());
      } else {
        webView = Webview(_windowsController!);
        if (!widget.isFit) {
          webView = Stack(
            children: [
              webView,
              Positioned.fill(
                child: GestureDetector(
                  onVerticalDragUpdate: (_) {},
                  onHorizontalDragUpdate: (_) {},
                  behavior: HitTestBehavior.opaque,
                ),
              ),
            ],
          );
        }
      }
    } else if (Platform.isAndroid) {
      webView = WebViewWidget(
        controller: _androidController,
        gestureRecognizers: widget.isFit
            ? {
                Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer()),
              }
            : <Factory<OneSequenceGestureRecognizer>>{}.toSet(),
      );
    } else {
      webView = const Center(child: Text("Unsupported platform"));
    }

    // cropRect가 전달된 경우, 웹뷰 콘텐츠만 FittedBox로 스케일링하고,
    // 플로팅 버튼은 FittedBox의 영향을 받지 않도록 별도 레이어에 배치합니다.
    if (widget.cropRect != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: FittedBox(
          fit: BoxFit.contain,
          child: ClipRect(
            child: SizedBox(
              width: widget.cropRect!.width,
              height: widget.cropRect!.height,
              child: Transform.translate(
                offset: Offset(-widget.cropRect!.left, -widget.cropRect!.top),
                child: webView,
              ),
            ),
          ),
        ),
        // child: Stack(
        //   children: [
        //     // FittedBox는 웹뷰 콘텐츠(크롭된 영역)에만 적용
        //     Positioned.fill(
        //       child: FittedBox(
        //         fit: BoxFit.fill,
        //         child: ClipRect(
        //           child: SizedBox(
        //             width: widget.cropRect!.width,
        //             height: widget.cropRect!.height,
        //             child: Transform.translate(
        //               offset:
        //                   Offset(-widget.cropRect!.left, -widget.cropRect!.top),
        //               child: webView,
        //             ),
        //           ),
        //         ),
        //       ),
        //     ),
        //     Positioned(
        //       top: 20,
        //       right: 16,
        //       child: Row(
        //         mainAxisSize: MainAxisSize.min,
        //         children: [
        //           FloatingActionButton(
        //             heroTag: "back",
        //             mini: true,
        //             onPressed: _goBack,
        //             child: const Icon(Icons.arrow_back),
        //           ),
        //           const SizedBox(width: 16),
        //           FloatingActionButton(
        //             heroTag: "forward",
        //             mini: true,
        //             onPressed: _goForward,
        //             child: const Icon(Icons.arrow_forward),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ],
        // ),
      );
    }

    // cropRect가 없으면 원래 widget.width x widget.height 크기로 표시
    return Container(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(child: webView),
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "back",
                  mini: true,
                  onPressed: _goBack,
                  child: const Icon(Icons.arrow_back),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "forward",
                  mini: true,
                  onPressed: _goForward,
                  child: const Icon(Icons.arrow_forward),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
