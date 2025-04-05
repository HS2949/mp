import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:mp_db/dialog/compression/image_CR_windows.dart';

class ImageCompressorMobile {
  static Future<File?> compressAndResize({
    required File inputFile,
    required int quality,
    int? targetWidth,
    int? targetHeight,
  }) async {
    try {
      // 0️⃣ 파일 확장자와 크기 확인: .webp이고 1MB 이하이면 바로 업로드 가능
      final String extensionName = path.extension(inputFile.path).toLowerCase();
      final int fileSize = await inputFile.length();
      if (extensionName == '.webp' && fileSize <= 1048576) { // 1MB = 1048576 바이트
        print("✅ 파일이 이미 .webp 형식이고 크기가 1MB 이하입니다. 바로 업로드 가능합니다.");
        return inputFile;
      }

      if (Platform.isWindows) {
        // Windows 환경 지원
        return await ImageCompressorWindows.compressAndResize(
          inputFile: inputFile,
          quality: quality,
          targetWidth: targetWidth,
          targetHeight: targetHeight,
        );
      } else if (Platform.isAndroid) {
        final String tempPath = (await getTemporaryDirectory()).path;
        final String outputPath = path.join(
          tempPath,
          '${DateTime.now().millisecondsSinceEpoch}.webp',
        );

        // autoCorrectionAngle: true 옵션 추가하여 EXIF 정보 기반 자동 회전 적용
        final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
          inputFile.absolute.path,
          outputPath,
          quality: quality,
          format: CompressFormat.webp,
          minWidth: targetWidth ?? 0,
          minHeight: targetHeight ?? 0,
          autoCorrectionAngle: true,
        );

        // XFile을 File로 변환 후 반환
        return compressedXFile != null ? File(compressedXFile.path) : null;
      } else {
        print("지원되지 않는 플랫폼");
        return null;
      }
    } catch (e) {
      print("이미지 압축 오류: $e");
      return null;
    }
  }
}
