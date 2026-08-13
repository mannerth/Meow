import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:meow/api/data_response.dart';
import 'package:meow/api/http.dart';

/// 腾讯云 COS 图片上传
///
/// 流程：
/// 1. 调用 `/cos/upload-image` 获取临时凭证与预生成的存储 key
/// 2. 使用临时密钥将文件直传至 COS
/// 3. 返回 COS 的 key，供业务接口作为图片 URL 提交
class CosUploadService {
  static const int _expireBuffer = 300;

  /// 上传多张图片，返回对应顺序的 COS key
  static Future<List<String>> uploadImages(List<File> files) async {
    if (files.isEmpty) return const [];
    final types = files
        .map((f) => f.path.split('.').last.toLowerCase())
        .where((t) => t.isNotEmpty)
        .toList();
    final credential = await _prepareUpload(types);
    final keys = credential.keys;
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final key = keys[i];
      final bytes = await files[i].readAsBytes();
      await _putObject(
        bucket: credential.bucket,
        region: credential.region,
        key: key,
        bytes: bytes,
        secretId: credential.tmpSecretId,
        secretKey: credential.tmpSecretKey,
        sessionToken: credential.sessionToken,
      );
      urls.add(key);
    }
    return urls;
  }

  static Future<_CosCredential> _prepareUpload(List<String> types) async {
    final response = await Http().post(
      '/cos/upload-image',
      data: {'types': types},
      allowRetry: false,
    );
    final json = response.data as Map<String, dynamic>;
    final data = DataResponse.fromJson(json).data;
    if (data is! Map<String, dynamic>) {
      throw Exception('获取上传凭证失败：${json['msg']}');
    }
    return _CosCredential.fromJson(data);
  }

  static Future<void> _putObject({
    required String bucket,
    required String region,
    required String key,
    required Uint8List bytes,
    required String secretId,
    required String secretKey,
    required String sessionToken,
  }) async {
    final host = '$bucket.cos.$region.myqcloud.com';
    final path = '/${_uriEncodeKey(key)}';
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final startTime = now - 60;
    final endTime = now + _expireBuffer;

    final contentType = _contentTypeForKey(key);
    final headers = <String, String>{
      'host': host,
      'x-cos-security-token': sessionToken,
      'content-length': bytes.length.toString(),
      'content-type': contentType,
    };

    final authorization = _sign(
      method: 'PUT',
      path: path,
      headers: headers,
      secretId: secretId,
      secretKey: secretKey,
      startTime: startTime,
      endTime: endTime,
    );

    final response = await Dio().put(
      'https://$host$path',
      data: bytes,
      options: Options(
        contentType: contentType,
        headers: {'Authorization': authorization, ...headers},
      ),
    );
    if (response.statusCode != null &&
        (response.statusCode! < 200 || response.statusCode! >= 300)) {
      throw Exception('上传图片失败：HTTP ${response.statusCode}');
    }
  }

  static String _sign({
    required String method,
    required String path,
    required Map<String, String> headers,
    required String secretId,
    required String secretKey,
    required int startTime,
    required int endTime,
  }) {
    final keyTime = '$startTime;$endTime';

    final sortedHeaders = headers.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final headerList = sortedHeaders.map((k) => k.toLowerCase()).toList();
    final httpHeaders = sortedHeaders
        .map((k) => '${k.toLowerCase()}=${_uriEncode(headers[k]!)}')
        .join('&');

    final httpString = '${method.toLowerCase()}\n$path\n\n$httpHeaders\n';
    final sha1HttpString = sha1.convert(utf8.encode(httpString)).toString();
    final stringToSign = 'sha1\n$keyTime\n$sha1HttpString\n';
    final signKey = Hmac(
      sha1,
      utf8.encode(secretKey),
    ).convert(utf8.encode(keyTime)).toString();
    final signature = Hmac(
      sha1,
      utf8.encode(signKey),
    ).convert(utf8.encode(stringToSign)).toString();

    return 'q-sign-algorithm=sha1&q-ak=$secretId'
        '&q-sign-time=$keyTime&q-key-time=$keyTime'
        '&q-header-list=${headerList.join(';')}&q-url-param-list='
        '&q-signature=$signature';
  }

  static String _uriEncode(String value) {
    final bytes = utf8.encode(value);
    final buffer = StringBuffer();
    for (final b in bytes) {
      final c = String.fromCharCode(b);
      if (_uriUnreserved(c)) {
        buffer.write(c);
      } else {
        buffer.write('%${b.toRadixString(16).toUpperCase().padLeft(2, '0')}');
      }
    }
    return buffer.toString();
  }

  static String _uriEncodeKey(String key) {
    return key.split('/').map(_uriEncode).join('/');
  }

  static bool _uriUnreserved(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 48 && code <= 57) ||
        (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        c == '-' ||
        c == '_' ||
        c == '.' ||
        c == '~';
  }

  static String _contentTypeForKey(String key) {
    final extension = key.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' || 'heif' => 'image/heic',
      _ => 'application/octet-stream',
    };
  }
}

class _CosCredential {
  final String bucket;
  final String region;
  final String tmpSecretId;
  final String tmpSecretKey;
  final String sessionToken;
  final List<String> keys;

  const _CosCredential({
    required this.bucket,
    required this.region,
    required this.tmpSecretId,
    required this.tmpSecretKey,
    required this.sessionToken,
    required this.keys,
  });

  factory _CosCredential.fromJson(Map<String, dynamic> json) => _CosCredential(
    bucket: json['bucket'] as String? ?? '',
    region: json['region'] as String? ?? '',
    tmpSecretId: json['tmpSecretId'] as String? ?? '',
    tmpSecretKey: json['tmpSecretKey'] as String? ?? '',
    sessionToken: json['sessionToken'] as String? ?? '',
    keys: (json['keys'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
  );
}
