import 'dart:io';

import 'package:flutter/material.dart';

void showNetworkImagePreview(BuildContext context, String url) {
  if (!_isValidUrl(url)) return;
  _showImagePreview(
    context,
    Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFE6E7EB),
        alignment: Alignment.center,
        child: const Icon(Icons.pets, color: Colors.grey),
      ),
    ),
  );
}

void showFileImagePreview(BuildContext context, File file) {
  _showImagePreview(
    context,
    Image.file(
      file,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFFE6E7EB),
        alignment: Alignment.center,
        child: const Icon(Icons.pets, color: Colors.grey),
      ),
    ),
  );
}

bool _isValidUrl(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return false;
  final uri = Uri.tryParse(value);
  if (uri == null) return false;
  if (!uri.hasScheme || uri.host.isEmpty) return false;
  return uri.isScheme('http') || uri.isScheme('https');
}

void _showImagePreview(BuildContext context, Widget image) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withAlpha(200),
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: image,
          ),
        ),
      ),
    ),
  );
}
