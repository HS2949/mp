import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

class ImageCompressor {
  static final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

  /// 입력 [inputFile]를 [width]x[height] 크기로 리사이징하고,
  /// [quality] (0~100) 값에 따라 압축하여 webp 포맷으로 변환합니다.
  /// 성공하면 변환된 이미지 파일을, 실패하면 null을 반환합니다.
  static Future<File?> compressAndResize({
    required File inputFile,
    required int quality,
    required int width,
    required int height,
  }) async {
    try {
      // 임시 디렉터리 경로 생성
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.webp';

      // FFmpeg 명령어 작성
      // - 입력 파일, scale 필터로 리사이즈, libwebp 코덱 사용, quality 적용 후 출력
      final String command =
          '-i "${inputFile.path}" -vf scale=$width:$height -c:v libwebp -quality $quality "$outputPath"';

      // FFmpeg 명령어 실행
      final int rc = await _flutterFFmpeg.execute(command);
      if (rc == 0) {
        // 변환 성공
        return File(outputPath);
      } else {
        print('FFmpeg 실행 실패 (rc: $rc)');
        return null;
      }
    } catch (e) {
      print('ImageCompressor 오류: $e');
      return null;
    }
  }
}
