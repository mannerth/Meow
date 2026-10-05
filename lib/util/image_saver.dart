import 'package:flutter/services.dart';

enum ImageSaveDestination { gallery, file, canceled }

class ImageSaver {
  static const _channel = MethodChannel('meow/image_saver');

  static Future<ImageSaveDestination> savePng(Uint8List bytes) async {
    final destination = await _channel.invokeMethod<String>('savePng', bytes);
    return switch (destination) {
      'gallery' => ImageSaveDestination.gallery,
      'file' => ImageSaveDestination.file,
      'canceled' => ImageSaveDestination.canceled,
      _ => throw PlatformException(code: 'SAVE_FAILED', message: '图片保存失败，请重试'),
    };
  }
}
