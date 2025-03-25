// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewerPage extends StatefulWidget {
  final String url;

  const PDFViewerPage({Key? key, required this.url}) : super(key: key);

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  bool _isLoading = true;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfController = PdfViewerController();
  

  // 패딩 관련 변수: 사용자 변경 가능하도록 변수로 지정
  final double incrementValue = 50.0;
  final double minPadding = 50.0;
  final double maxPadding = 800.0;
  double _horizontalPadding = 0.0;

  // ctrl 키가 눌렸는지 여부
  bool _isCtrlPressed = false;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _pdfController.dispose();
    super.dispose();
  }

  // 키보드 이벤트 핸들러: ctrl 키 상태 및 +/- 입력에 따라 패딩을 조절
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
      }
      // ctrl 키 눌림 상태 감지
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight) {
        setState(() {
          _isCtrlPressed = true;
        });
      }
      // '+' 또는 numpad '+' 입력 시 패딩 증가
      if (event.logicalKey == LogicalKeyboardKey.equal ||
          event.logicalKey == LogicalKeyboardKey.numpadAdd) {
        setState(() {
          _horizontalPadding = (_horizontalPadding + incrementValue)
              .clamp(minPadding, maxPadding);
        });
      }
      // '-' 또는 numpad '-' 입력 시 패딩 감소
      else if (event.logicalKey == LogicalKeyboardKey.minus ||
          event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
        setState(() {
          _horizontalPadding = (_horizontalPadding - incrementValue)
              .clamp(minPadding, maxPadding);
        });
      }
    } else if (event is RawKeyUpEvent) {
      // ctrl 키 해제 상태 감지
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight) {
        setState(() {
          _isCtrlPressed = false;
        });
      }
    }
  }

  // 마우스 휠 이벤트 핸들러: ctrl 키가 눌린 경우 패딩 값을 조절
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      if (RawKeyboard.instance.keysPressed
              .contains(LogicalKeyboardKey.controlLeft) ||
          RawKeyboard.instance.keysPressed
              .contains(LogicalKeyboardKey.controlRight)) {
        setState(() {
          // 휠 스크롤 방향에 따라 패딩 조절
          if (event.scrollDelta.dy > 0) {
            _horizontalPadding = (_horizontalPadding + incrementValue)
                .clamp(minPadding, maxPadding);
          } else {
            _horizontalPadding = (_horizontalPadding - incrementValue)
                .clamp(minPadding, maxPadding);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ctrl 키가 눌린 동안에는 pdf 뷰어에 대한 스크롤 등 이벤트를 막기 위해 AbsorbPointer 사용
    Widget pdfViewer = SfPdfViewer.network(
      widget.url,
      key: _pdfViewerKey,
      controller: _pdfController,
      enableTextSelection: true,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      interactionMode: PdfInteractionMode.selection,
      initialZoomLevel: 0.75,
      onDocumentLoaded: (details) {
        setState(() {
          _isLoading = false;
        });
      },
      onDocumentLoadFailed: (details) {
        setState(() {
          _isLoading = false;
        });
        showOverlayMessage(context, "PDF 로드 실패: ${details.description}");
      },
    );

    if (_isCtrlPressed) {
      pdfViewer = AbsorbPointer(child: pdfViewer);
    }

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Listener(
        onPointerSignal: _handlePointerSignal,
        child: Scaffold(
          appBar: AppBar(
            title: Wrap(
              children: [
                Text(
                  'PDF Viewer : ',
                  style: AppTheme.appbarTitleTextStyle
                      .copyWith(color: AppTheme.text2Color),
                ),
                SelectableText(
                  urlFileName(widget.url),
                  style: AppTheme.appbarTitleTextStyle,
                ),
                SizedBox(width: 30),
                Text(
                  'Ctrl + 마우스 휠 또는 +/- 키  ☞ 확대 / 축소',
                  style: AppTheme.appbarTitleTextStyle
                      .copyWith(color: AppTheme.textLabelColor, fontSize: 13),
                ),
              ],
            ),
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: Stack(
              children: [
                pdfViewer,
                if (_isLoading)
                  LayoutBuilder(builder: (context, constraints) {
                    double screenWidth = constraints.maxWidth;
                    return Stack(
                      children: [
                        Container(
                          color: Colors.white,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        Center(
                          child: Opacity(
                            opacity: 0.5,
                            child: Container(
                              width: min(screenWidth * 0.5, 300),
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                      'assets/images/miceplan_font.png'),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
