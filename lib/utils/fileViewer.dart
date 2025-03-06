import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFViewerPage extends StatefulWidget {
  final String url;
  final String fileName;

  const PDFViewerPage({Key? key, required this.url, required this.fileName})
      : super(key: key);

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  bool _isLoading = true;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final PdfViewerController _pdfController =
      PdfViewerController(); // ✅ PDF 컨트롤러 추가
  double _zoomLevel = 1.0; // 초기 줌 레벨
  final FocusNode _focusNode = FocusNode(); // 키보드 입력 포커스 관리

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus(); // 키 입력 포커스 요청
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _pdfController.dispose(); // PDF 컨트롤러 해제
    super.dispose();
  }

  // 키보드 입력 감지 및 줌 업데이트
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.equal || // "+" 키 (일반 키보드)
          event.logicalKey == LogicalKeyboardKey.numpadAdd) {
        // "+" 키 (숫자 패드)
        _zoomIn();
      } else if (event.logicalKey ==
              LogicalKeyboardKey.minus || // "-" 키 (일반 키보드)
          event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
        // "-" 키 (숫자 패드)
        _zoomOut();
      }
    }
  }

  // 줌 인 (최대 3.0배)
  void _zoomIn() {
    setState(() {
      _zoomLevel += 0.1;
      if (_zoomLevel > 3.0) _zoomLevel = 3.0;
      _pdfController.zoomLevel = _zoomLevel; // ✅ 줌 적용
    });
  }

  // 줌 아웃 (최소 0.5배)
  void _zoomOut() {
    setState(() {
      _zoomLevel -= 0.1;
      if (_zoomLevel < 0.5) _zoomLevel = 0.5;
      _pdfController.zoomLevel = _zoomLevel; // ✅ 줌 적용
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent, // ✅ 키보드 이벤트 감지
      child: Scaffold(
          appBar: AppBar(title: Text(widget.fileName)),
          body: Stack(
            children: [
              SfPdfViewer.network(
                widget.url,
                key: _pdfViewerKey,
                controller: _pdfController,
                enableTextSelection: true, // ✅ 텍스트 선택 활성화
                canShowScrollHead: true, // ✅ 스크롤 헤드 활성화
                canShowScrollStatus: true, // ✅ 현재 페이지 상태 표시
                interactionMode:
                    PdfInteractionMode.selection, // ✅ 기본 모드를 텍스트 선택으로 설정
                initialZoomLevel: 0.75, // ✅ 초기 줌 설정 (기본보다 25% 축소)
                onDocumentLoaded: (details) {
                  setState(() {
                    _isLoading = false;
                  });
                },
                onDocumentLoadFailed: (details) {
                  setState(() {
                    _isLoading = false;
                  });
                  showOverlayMessage(
                      context, "PDF 로드 실패: ${details.description}");
                },
              ),
              // 로딩 중일 때 원하는 배경색과 로딩 인디케이터를 표시
              if (_isLoading)
                LayoutBuilder(builder: (context, constraints) {
                  double screenWidth = constraints.maxWidth; // 화면 너비
                  return Stack(
                    children: [
                      Container(
                        color: Colors.white, // 로딩 중 표시할 배경색
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      Center(
                        child: Opacity(
                          opacity: 0.5,
                          child: Container(
                            width: min(screenWidth * 0.5, 300), // 화면 너비의 50%
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                    'assets/images/miceplan_font.png'), // 배경 이미지 경로
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
          )),
    );
  }
}
