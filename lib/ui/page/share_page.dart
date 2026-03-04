import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/cat.dart';
import 'package:meow/model/user.dart';
import 'package:meow/ui/page/cat_select_page.dart';
import 'package:meow/ui/page/new_cat_page.dart';

/// 发布动态页面
class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  Cat? _selectedCat;
  Campus? _selectedCampus;
  final List<String> _images = [];
  bool _uploading = false;
  bool _publishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _goToNewCat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NewCatPage()),
    );
  }

  bool get _isBusy => _uploading || _publishing;

  Future<void> _selectCat() async {
    final selectedCat = await Navigator.of(context).push<Cat>(
      MaterialPageRoute(builder: (_) => const CatSelectPage(selectable: true)),
    );
    if (selectedCat == null) return;
    setState(() {
      _selectedCat = selectedCat;
    });
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
    await _uploadImages([image]);
  }

  Future<void> _pickFromGallery() async {
    if (_images.length >= 9) {
      _showMessage('最多添加 9 张图片');
      return;
    }
    final images = await _imagePicker.pickMultiImage(limit: 9 - _images.length);
    if (images.isEmpty) return;
    await _uploadImages(images);
  }

  Future<void> _uploadImages(List<XFile> images) async {
    setState(() => _uploading = true);
    try {
      for (final image in images) {
        try {
          final url = await Http().uploadImage(image);
          if (!_images.contains(url)) {
            _images.add(url);
          }
        } catch (error) {
          _showMessage('图片上传失败，请稍后重试');
        }
      }
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removeImage(String url) {
    setState(() => _images.remove(url));
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      _showMessage('请填写标题');
      return;
    }
    if (content.isEmpty) {
      _showMessage('请填写内容');
      return;
    }
    setState(() => _publishing = true);
    try {
      final payload = <String, dynamic>{
        'content': '$title\n$content',
        'media': _images,
        'relatedCatIds': _selectedCat?.id ?? '',
        'location': _selectedCampus?.name ?? '',
      };
      await Http().post('/moments', data: payload);
      if (!mounted) return;
      _showMessage('发布成功，等待审核');
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _images.clear();
        _selectedCat = null;
        _selectedCampus = null;
      });
    } catch (error) {
      _showMessage('发布失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _publishing = false);
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
        title: const Text('分享趣事'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
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
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: '加个有趣的标题...',
                      border: InputBorder.none,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(height: 1),
                  TextField(
                    controller: _contentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: '分享这只猫咪的可爱瞬间...\n(例如：今天在食堂门口碰瓷，给撸才让走😺)',
                      border: InputBorder.none,
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                children: [
                  Row(
                    children: [
                      _MediaActionCard(
                        icon: Icons.photo_camera_outlined,
                        label: '拍一张',
                        highlight: true,
                        onTap: _isBusy ? null : _pickFromCamera,
                      ),
                      const SizedBox(width: 12),
                      _MediaActionCard(
                        icon: Icons.photo_library_outlined,
                        label: '相册',
                        onTap: _isBusy ? null : _pickFromGallery,
                      ),
                      const SizedBox(width: 12),
                      const _MediaActionCard(
                        icon: Icons.videocam_outlined,
                        label: '视频',
                        enabled: false,
                      ),
                    ],
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
                  _ActionRow(
                    icon: Icons.pets,
                    title: '关联猫咪',
                    value: _selectedCat == null ? '选择主角' : _selectedCat!.name,
                    onTap: _selectCat,
                    avatarUrl: _selectedCat?.avatar,
                  ),
                  const Divider(height: 1),
                  _ActionRow(
                    icon: Icons.place,
                    title: '所在位置',
                    value: _selectedCampus?.name ?? '选择校区',
                    onTap: _selectCampus,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isBusy ? null : _goToNewCat,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('找不到它？为新面孔建立档案'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF4B24D),
                  side: const BorderSide(color: Color(0xFFF4B24D), width: 1.2),
                  shape: const StadiumBorder(),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isBusy ? null : _publish,
                  icon: const Icon(Icons.send),
                  label: const Text('立即发布'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6C14D),
                    foregroundColor: Colors.black87,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '内容将由管理员审核后公开展示',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              // 底部留白，避免被悬浮按钮遮挡
              SizedBox(height: 120),
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

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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

class _MediaActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool highlight;
  final VoidCallback? onTap;

  const _MediaActionCard({
    required this.icon,
    required this.label,
    this.enabled = true,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contentColor = enabled
        ? (highlight ? const Color(0xFFF4B24D) : const Color(0xFF7B8593))
        : const Color(0xFFB0B4BA);
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 96,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  highlight ? const Color(0xFFF6C14D) : const Color(0xFFE2E5EA),
              width: 1.2,
            ),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: contentColor),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: contentColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  final String? avatarUrl;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFFFF4E0),
        backgroundImage: avatarUrl == null || avatarUrl!.isEmpty
            ? null
            : NetworkImage(avatarUrl!),
        child: avatarUrl == null || avatarUrl!.isEmpty
            ? Icon(icon, color: const Color(0xFFF4B24D), size: 18)
            : null,
      ),
      title: Text(
        title,
        style:
            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<String> images;
  final ValueChanged<String> onRemove;

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
            (url) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    url,
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
                        onPressed: () => onRemove(url),
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
