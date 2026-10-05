import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:meow/api/http.dart';

class CommunityService {
  static Future<Uint8List> fetchGroupQrCode({CancelToken? cancelToken}) async {
    final response = await Http().get<Map<String, dynamic>>(
      '/community/group-qrcode',
      options: Options(extra: {Http.skipAuthenticationKey: true}),
      cancelToken: cancelToken,
    );
    final body = response.data;
    final data = body?['data'];
    final url = data is Map ? data['qrcodeUrl'] : null;
    final uri = url is String ? Uri.tryParse(url) : null;
    if (response.statusCode != 200 ||
        (body?['code'] != 0 && body?['code'] != 200) ||
        uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const FormatException('二维码地址无效');
    }

    // 使用公开请求下载，避免把业务 Token 发送给图片存储服务。
    final imageResponse = await Http().get<List<int>>(
      uri.toString(),
      options: Options(
        responseType: ResponseType.bytes,
        extra: {Http.skipAuthenticationKey: true},
      ),
      cancelToken: cancelToken,
    );
    final bytes = imageResponse.data;
    if (imageResponse.statusCode != 200 || bytes == null || bytes.isEmpty) {
      throw const FormatException('二维码图片无效');
    }
    // 预览与保存使用同一份 PNG，兼容接口返回的 JPEG 等图片格式。
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    try {
      final frame = await codec.getNextFrame();
      try {
        final png = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (png == null) throw const FormatException('二维码图片无效');
        return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}
