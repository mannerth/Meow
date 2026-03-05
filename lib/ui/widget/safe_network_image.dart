import 'package:flutter/material.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (!_isValidUrl(url)) {
      return _buildFallback();
    }
    final image = Image.network(
      formatUrl(url!),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => _buildFallback(),
    );
    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _buildFallback() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: const Color(0xFFE6E7EB),
          alignment: Alignment.center,
          child: const Icon(Icons.pets, color: Color(0xFFB0B4BA)),
        );
  }

  bool _isValidUrl(String? raw) {
    if (raw == null) return false;
    final value = raw.trim();
    if (value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    if (!uri.hasScheme || uri.host.isEmpty) return false;
    return uri.isScheme('http') || uri.isScheme('https');
  }

  String formatUrl(String? raw) {
    if (raw == null) return '';
    final value = raw.trim();
    if (value.isEmpty) return '';
    if( value.startsWith('https://example.com')) return '';
    final uri = Uri.tryParse(value);
    if (uri == null) return '';
    if (!uri.hasScheme || uri.host.isEmpty) return '';
    if (uri.isScheme('http') || uri.isScheme('https')) {
      return value;
    }
    return '';
  }
}
