import 'dart:io';
// import 'dart:typed_data';
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
        final String outputPath = path.join(tempPath, '${DateTime.now().millisecondsSinceEpoch}.webp');

        final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
          inputFile.absolute.path,
          outputPath,
          quality: quality,
          format: CompressFormat.webp,
          minWidth: targetWidth ?? 0,
          minHeight: targetHeight ?? 0,
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
