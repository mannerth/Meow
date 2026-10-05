import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:meow/api/service/community_service.dart';
import 'package:meow/util/image_saver.dart';

class CommunityQrCodeDialog extends StatefulWidget {
  const CommunityQrCodeDialog({super.key});

  @override
  State<CommunityQrCodeDialog> createState() => _CommunityQrCodeDialogState();
}

class _CommunityQrCodeDialogState extends State<CommunityQrCodeDialog> {
  final _cancelToken = CancelToken();
  Uint8List? _bytes;
  bool _loading = true;
  bool _saving = false;
  bool _loadFailed = false;
  String? _saveMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final bytes = await CommunityService.fetchGroupQrCode(
        cancelToken: _cancelToken,
      );
      if (mounted) setState(() => _bytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final bytes = _bytes;
    if (bytes == null || _saving) return;
    setState(() {
      _saving = true;
      _saveMessage = null;
    });
    try {
      final destination = await ImageSaver.savePng(bytes);
      if (!mounted) return;
      setState(() {
        _saveMessage = switch (destination) {
          ImageSaveDestination.gallery => '已保存到相册',
          ImageSaveDestination.file => '图片已保存',
          ImageSaveDestination.canceled => '已取消保存',
        };
      });
    } catch (_) {
      if (mounted) setState(() => _saveMessage = '图片保存失败，请重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '联系我们',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '扫码加入猫猫图鉴交流群',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 1,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _loadFailed
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image_outlined, size: 40),
                            const SizedBox(height: 12),
                            const Text('二维码加载失败，请重试'),
                            TextButton(
                              onPressed: _load,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onLongPress: _saving ? null : _save,
                        child: Image.memory(
                          _bytes!,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                          semanticLabel: '猫猫图鉴交流群二维码',
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                _saveMessage ?? '长按二维码或点击下方按钮保存图片',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _bytes == null || _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC32),
                    foregroundColor: const Color(0xFF513900),
                    minimumSize: const Size(0, 48),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: Text(_saving ? '正在保存…' : '保存图片'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
