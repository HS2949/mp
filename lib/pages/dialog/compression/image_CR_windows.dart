import 'dart:io';
// import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCompressorWindows {
  static Future<File?> compressAndResize({
    required File inputFile,
    required int quality,
    int? targetWidth,
    int? targetHeight,
  }) async {
    try {
      // 1️⃣ 릴리즈 모드에서 cwebp.exe의 위치 찾기
      final Directory appDir = Directory(Platform.resolvedExecutable).parent;
      String cwebpPath;

      if (Platform.environment.containsKey('FLUTTER_ASSETS')) {
        // ✅ 릴리즈 모드에서 실행할 경로
        cwebpPath = path.join(appDir.path, 'data', 'flutter_assets', 'assets',
            'bin', 'cwebp.exe');
      } else {
        // ✅ 디버그 모드에서는 assets 경로에서 로드
        final Directory tempDir = await getTemporaryDirectory();
        cwebpPath = path.join(tempDir.path, "cwebp.exe");

        if (!File(cwebpPath).existsSync()) {
          print("⚠ cwebp.exe가 없으므로 복사합니다...");
          ByteData data = await rootBundle.load('assets/bin/cwebp.exe');
          List<int> bytes = data.buffer.asUint8List();
          await File(cwebpPath).writeAsBytes(bytes, flush: true);
        }
      }

      // 2️⃣ 변환된 WebP 저장 경로 설정
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath = path.join(
          tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.webp');

      // 기본 변환 명령어 구성
      List<String> args = [
        '-q',
        quality.toString(),
        inputFile.path,
        '-o',
        outputPath
      ];

      // 가로, 세로 값이 유효한 경우에만 -resize 옵션 추가 (각 값 개별 인자로 전달)
      if (targetWidth != null &&
          targetHeight != null &&
          targetWidth > 0 &&
          targetHeight > 0) {
        args.insertAll(
            2, ['-resize', targetWidth.toString(), targetHeight.toString()]);
      }

      // 실행 명령어 출력 (디버깅)
      print("🛠 실행 명령어: $cwebpPath ${args.join(" ")}");

      // cwebp.exe 실행
      ProcessResult result = await Process.run(cwebpPath, args);

      // 결과 로그 출력
      print("✅ 실행 결과: ${result.stdout}");
      print("⚠ 오류 메시지: ${result.stderr}");

      if (result.exitCode == 0) {
        print("✅ Windows WebP 변환 및 리사이징 성공: $outputPath");
        return File(outputPath);
      } else {
        print("❌ Windows WebP 변환 실패: ${result.stderr}");
        return null;
      }
    } catch (e) {
      print("⚠ Windows 이미지 변환 오류: $e");
      return null;
    }
  }
}
