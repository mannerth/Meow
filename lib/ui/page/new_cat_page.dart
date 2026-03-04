import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/user.dart';
import 'package:meow/provider/auth_provider.dart';

class NewCatPage extends ConsumerStatefulWidget {
  const NewCatPage({super.key});

  @override
  ConsumerState<NewCatPage> createState() => _NewCatPageState();
}

class _NewCatPageState extends ConsumerState<NewCatPage> {
  final TextEditingController _tempNameController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final List<XFile> _images = [];
  final List<String> _selectedTraits = [];
  Campus? _selectedCampus;

  bool _submitting = false;

  static const List<String> _traitOptions = [
    '亲人',
    '怕人',
    '给撸',
    '凶猛/哈气',
    '贪吃',
    '受伤',
    '剪耳(绝育)',
  ];

  bool get _isBusy => _submitting;

  @override
  void initState() {
    super.initState();
    _selectedCampus = ref.read(authStateProvider).user?.campus;
  }

  @override
  void dispose() {
    _tempNameController.dispose();
    _colorController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectCampus() async {
    final selected = await showModalBottomSheet<Campus>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: Campus.values
                .map(
                  (item) => ListTile(
                    title: Text(item.name),
                    onTap: () => Navigator.of(context).pop(item),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (selected == null) return;
    setState(() => _selectedCampus = selected);
  }

  Future<void> _pickImageOption() async {
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
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('拍照'),
                onTap: () => Navigator.of(context).pop('camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('相册选择'),
                onTap: () => Navigator.of(context).pop('gallery'),
              ),
            ],
          ),
        );
      },
    );
    if (action == 'camera') {
      await _pickFromCamera();
    }
    if (action == 'gallery') {
      await _pickFromGallery();
    }
  }

  Future<void> _pickFromCamera() async {
    if (_images.length >= 9) {
      _showMessage('最多添加 9 张图片');
      return;
    }
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() => _images.add(image));
  }

  Future<void> _pickFromGallery() async {
    if (_images.length >= 9) {
      _showMessage('最多添加 9 张图片');
      return;
    }
    final images = await _imagePicker.pickMultiImage(limit: 9 - _images.length);
    if (images.isEmpty) return;
    setState(() => _images.addAll(images));
  }

  void _removeImage(XFile image) {
    setState(() => _images.remove(image));
  }

  void _toggleTrait(String label) {
    setState(() {
      if (_selectedTraits.contains(label)) {
        _selectedTraits.remove(label);
      } else {
        _selectedTraits.add(label);
      }
    });
  }

  Future<void> _submit() async {
      final tempName = _tempNameController.text.trim();
      final color = _colorController.text.trim();
      final location = _locationController.text.trim();

      if (color.isEmpty) {
        _showMessage('请填写猫咪毛色');
        return;
      }
      if (color.length > 12) {
        _showMessage('毛色最多输入 12 个字');
        return;
      }
      if (tempName.length > 12) {
        _showMessage('拟定花名最多 12 个字');
        return;
      }
      if (location.length > 40) {
        _showMessage('位置描述过长，请精简');
        return;
      }
    if (_selectedCampus == null) {
      _showMessage('请选择发现校区');
      return;
    }
    if (location.isEmpty) {
      _showMessage('请填写发现位置');
      return;
    }
    if (_images.isEmpty) {
      _showMessage('请上传清晰照片');
      return;
    }

    setState(() => _submitting = true);
    try {
      final files = <MultipartFile>[];
      for (final image in _images) {
        files.add(
          await MultipartFile.fromFile(
            image.path,
            filename: image.name,
          ),
        );
      }
      final formData = FormData.fromMap({
        'color': color,
        'campus': _selectedCampus!.code.toString(),
        'location': location,
        'tags': _selectedTraits,
        'images': files,
        if (tempName.isNotEmpty) 'tempName': tempName,
      });
      await Http().post(
        '/new-cats',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      if (!mounted) return;
      _showMessage('提交成功，等待审核');
      _tempNameController.clear();
      _colorController.clear();
      _locationController.clear();
      setState(() {
        _images.clear();
        _selectedTraits.clear();
      });
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      _showMessage('提交失败，请稍后重试');
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        title: const Text('新猫建档'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SectionCard(
                children: [
                  InkWell(
                    onTap: _isBusy ? null : _pickImageOption,
                    borderRadius: BorderRadius.circular(120),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE1E3E8),
                                width: 2,
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_camera_outlined,
                                    color: Color(0xFFB0B4BA)),
                                SizedBox(height: 8),
                                Text(
                                  '上传大头照',
                                  style: TextStyle(
                                    color: Color(0xFF8B9099),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '清晰正面为佳',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFB0B4BA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '照片将用于 AI 识别和档案封面，请认真拍摄',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9AA0A9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_images.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ImageGrid(images: _images, onRemove: _removeImage),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  const _FieldTitle(title: '拟定花名（选填）'),
                  TextField(
                    controller: _tempNameController,
                    decoration: const InputDecoration(
                      hintText: '例如：小黑、大黄...(最终由投票决定)',
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  const _FieldTitle(title: '毛色分类', required: true),
                  TextField(
                    controller: _colorController,
                    decoration: const InputDecoration(
                      hintText: '例如：橘猫、三花、奶牛、狸花',
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  const _FieldTitle(title: '发现地点', required: true),
                  Row(
                    children: [
                      InkWell(
                        onTap: _selectCampus,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3DD),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedCampus?.name ?? '选择校区',
                                style: const TextStyle(
                                  color: Color(0xFFB16A00),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.expand_more,
                                  size: 18, color: Color(0xFFB16A00)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            hintText: '详细位置，如：食堂北门',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  const _FieldTitle(title: '初见性格'),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _traitOptions
                        .map(
                          (label) => _TraitChip(
                            label: label,
                            selected: _selectedTraits.contains(label),
                            onTap: () => _toggleTrait(label),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isBusy ? null : _submit,
                  icon: const Icon(Icons.check),
                  label: const Text('提交档案审核'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6C14D),
                    foregroundColor: Colors.black87,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  '感谢你为山大流浪猫数据库做出的贡献 ❤',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 100),
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

class _FieldTitle extends StatelessWidget {
  final String title;
  final bool required;

  const _FieldTitle({required this.title, this.required = false});

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(title, style: baseStyle),
          if (required)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text('*', style: TextStyle(color: Color(0xFFE14B4B))),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _TraitChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TraitChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected ? const Color(0xFFF6C14D) : Colors.white;
    final textColor = selected ? Colors.black87 : const Color(0xFF6F7681);
    final borderColor = selected ? const Color(0xFFF6C14D) : const Color(0xFFE4E6EB);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
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

class _ImageGrid extends StatelessWidget {
  final List<XFile> images;
  final ValueChanged<XFile> onRemove;

  const _ImageGrid({required this.images, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: images
          .map(
            (image) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(image.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFE6E7EB),
                      alignment: Alignment.center,
                      child: const Icon(Icons.pets, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: () => onRemove(image),
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
