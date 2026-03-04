import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/cat.dart';
import 'package:meow/model/user.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/ui/page/cat_select_page.dart';
import 'package:meow/ui/widget/image_preview.dart';

class SosPage extends ConsumerStatefulWidget {
  const SosPage({super.key});

  @override
  ConsumerState<SosPage> createState() => _SosPageState();
}

class _SosPageState extends ConsumerState<SosPage> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  Cat? _selectedCat;
  final List<XFile> _media = [];
  final List<String> _selectedSymptoms = [];
  List<String> _symptomOptions = [];

  bool _loadingTags = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadSymptomTags();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isBusy => _submitting;

  Future<void> _loadSymptomTags() async {
    setState(() => _loadingTags = true);
    try {
      final response = await Http().get('/sos/tags');
      final json = response.data as Map<String, dynamic>;
      final data = json['data'];
      if (data is List) {
        _symptomOptions = data.map((item) => item.toString()).toList();
      }
    } catch (error) {
      _symptomOptions = ['外伤出血', '呼吸困难', '无法站立', '口炎/流涎', '车祸/撞击', '精神萎靡'];
    } finally {
      if (mounted) setState(() => _loadingTags = false);
    }
  }

  Future<void> _selectCat() async {
    final selected = await Navigator.of(context).push<Cat>(
      MaterialPageRoute(builder: (_) => const CatSelectPage(selectable: true)),
    );
    if (selected == null) return;
    setState(() => _selectedCat = selected);
  }

  Future<void> _pickCatOption() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.pets),
                title: const Text('选择猫咪'),
                onTap: () => Navigator.of(context).pop('select'),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('不确定是哪只'),
                onTap: () => Navigator.of(context).pop('unknown'),
              ),
            ],
          ),
        );
      },
    );
    if (action == 'select') {
      await _selectCat();
      return;
    }
    if (action == 'unknown') {
      _clearSelectedCat();
    }
  }

  void _clearSelectedCat() {
    setState(() => _selectedCat = null);
  }

  void _toggleSymptom(String label) {
    setState(() {
      if (_selectedSymptoms.contains(label)) {
        _selectedSymptoms.remove(label);
      } else {
        _selectedSymptoms.add(label);
      }
    });
  }

  Future<void> _pickFromCamera() async {
    if (_media.length >= 9) {
      _showMessage('最多添加 9 张照片');
      return;
    }
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => _media.add(image));
  }

  Future<void> _pickFromGallery() async {
    if (_media.length >= 9) {
      _showMessage('最多添加 9 张照片');
      return;
    }
    final images = await _imagePicker.pickMultiImage(limit: 9 - _media.length);
    if (images.isEmpty) return;
    setState(() => _media.addAll(images));
  }

  void _removeMedia(XFile image) {
    setState(() => _media.remove(image));
  }

  Future<void> _submit() async {
    final location = _locationController.text.trim();
    final description = _descriptionController.text.trim();
    if (location.isEmpty) {
      _showMessage('请填写发现位置');
      return;
    }
    if (_selectedSymptoms.isEmpty) {
      _showMessage('请选择症状标签');
      return;
    }
    if (description.isEmpty) {
      _showMessage('请补充具体症状');
      return;
    }
    if (_media.isEmpty) {
      _showMessage('请上传现场照片或视频');
      return;
    }

    setState(() => _submitting = true);
    try {
      final campusCode = ref.read(authStateProvider).user?.campus?.code;
      final files = <MultipartFile>[];
      for (final image in _media) {
        files.add(
          await MultipartFile.fromFile(
            image.path,
            filename: image.name,
          ),
        );
      }
      final formData = FormData.fromMap({
        if (_selectedCat != null) 'catId': _selectedCat!.id,
        'campus': (campusCode ?? 0).toString(),
        'location': location,
        'symptoms': _selectedSymptoms,
        'description': description,
        'media': files,
      });
      await Http().post(
        '/sos',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (!mounted) return;
      _showMessage('上报成功，已通知协会同学');
      _locationController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedCat = null;
        _selectedSymptoms.clear();
        _media.clear();
      });
    } catch (error) {
      _showMessage('上报失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: const Color(0xFFB45D5D),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFFB04545)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          '紧急病情上报',
          style: TextStyle(
            color: Color(0xFFB04545),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              _HeroBanner(subtitleStyle: subtitleStyle),
              const SizedBox(height: 16),
              _SectionTitle(title: '涉及猫咪'),
              _SelectCard(
                title: _selectedCat?.name ?? '点击选择（如不认识选“未知”）',
                subtitle: _selectedCat?.basicLocation ?? '点击选择猫咪',
                leading: _selectedCat?.avatar,
                onTap: _pickCatOption,
                trailing: _selectedCat == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _clearSelectedCat,
                      ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: '发现位置'),
              _InputCard(
                child: TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: '例如：食堂北门灌木丛',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: '主要症状（多选）'),
              _InputCard(
                child: _loadingTags
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _symptomOptions
                            .map(
                              (label) => _SymptomChip(
                                label: label,
                                selected: _selectedSymptoms.contains(label),
                                onTap: () => _toggleSymptom(label),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: '具体症状'),
              _InputCard(
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '请详细描述猫猫的症状~',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: '现场照片/视频'),
              _MediaUploadCard(
                onCamera: _isBusy ? null : _pickFromCamera,
                onGallery: _isBusy ? null : _pickFromGallery,
              ),
              if (_media.isNotEmpty) ...[
                const SizedBox(height: 12),
                _MediaGrid(media: _media, onRemove: _removeMedia),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isBusy ? null : _submit,
                  icon: const Icon(Icons.report_gmailerrorred_outlined),
                  label: const Text('立即上报求助'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE64A4A),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '请确保自身安全的情况下进行求助',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          if (_isBusy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final TextStyle? subtitleStyle;

  const _HeroBanner({this.subtitleStyle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE3E3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_hospital,
              color: Color(0xFFE64A4A),
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '紧急病情上报',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB04545),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '请确保自身安全的情况下进行求助',
                  style: subtitleStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SelectCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? leading;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SelectCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = leading != null && leading!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: hasAvatar
                  ? () => showNetworkImagePreview(context, leading!)
                  : null,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFFFF2F2),
                backgroundImage: hasAvatar ? NetworkImage(leading!) : null,
                child: hasAvatar
                    ? null
                    : const Icon(Icons.pets, color: Color(0xFFE64A4A)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final Widget child;

  const _InputCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SymptomChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SymptomChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFE64A4A) : const Color(0xFFF3F4F6);
    final textColor = selected ? Colors.white : const Color(0xFF333333);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFFE64A4A) : const Color(0xFFE6E7EB),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: textColor, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _MediaUploadCard extends StatelessWidget {
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;

  const _MediaUploadCard({this.onCamera, this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5B5B5), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('拍照'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE64A4A),
                side: const BorderSide(color: Color(0xFFE64A4A)),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('相册'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE64A4A),
                side: const BorderSide(color: Color(0xFFE64A4A)),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<XFile> media;
  final ValueChanged<XFile> onRemove;

  const _MediaGrid({required this.media, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: media
          .map(
            (file) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PreviewImageTile(file: file),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Material(
                      color: Colors.white.withAlpha(230),
                      shape: const CircleBorder(),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: () => onRemove(file),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFE14B4B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PreviewImageTile extends StatelessWidget {
  final XFile file;

  const _PreviewImageTile({required this.file});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showFileImagePreview(context, File(file.path)),
      child: Image.file(
        File(file.path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFE6E7EB),
          alignment: Alignment.center,
          child: const Icon(Icons.pets, color: Colors.grey),
        ),
      ),
    );
  }
}

extension on Cat {
  String get basicLocation {
    if (campus.isEmpty) return '点击选择猫咪';
    if (locationName.isEmpty) return campus;
    return '$campus · $locationName';
  }
}
