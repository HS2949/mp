import 'dart:io';
import 'package:mp_db/dialog/compression/image_CR_mobile.dart';
import 'package:mp_db/dialog/compression/image_CR_windows.dart';

class ImageCompressor {
  static Future<File?> compressAndResize({
    required File inputFile,
    required int quality,
    int? targetWidth,
    int? targetHeight,
  }) async {
    if (Platform.isWindows) {
      // Windows 네이티브 앱
      return await ImageCompressorWindows.compressAndResize(
        inputFile: inputFile,
        quality: quality,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
    } else if (Platform.isAndroid) {
      // Android 네이티브 앱
      return await (ImageCompressorMobile.compressAndResize(
        inputFile: inputFile,
        quality: quality,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      ));
    } else {
      print("지원되지 않는 플랫폼");
      return null;
    }
  }
}
