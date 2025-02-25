import 'dart:io';
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
      final String cwebpPath = "assets/bin/cwebp.exe"; // 프로젝트 내 포함된 경로

      if (!File(cwebpPath).existsSync()) {
        print("❌ cwebp.exe 파일이 없습니다.");
        return null;
      }

      // 변환된 WebP 이미지 저장할 임시 경로 생성 (확장자가 .webp인지 확인)
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.webp');

      // 기본 변환 명령어 구성
      List<String> args = ['-q', quality.toString(), inputFile.path, '-o', outputPath];

      // 가로, 세로 값이 유효한 경우에만 -resize 옵션 추가 (각 값 개별 인자로 전달)
      if (targetWidth != null && targetHeight != null && targetWidth > 0 && targetHeight > 0) {
        args.insertAll(2, ['-resize', targetWidth.toString(), targetHeight.toString()]);
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
