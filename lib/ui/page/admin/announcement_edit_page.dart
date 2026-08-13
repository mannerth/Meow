import 'package:flutter/material.dart';
import 'package:meow/api/service/announcement_service.dart';
import 'package:meow/model/notification.dart';

class AnnouncementEditPage extends StatefulWidget {
  const AnnouncementEditPage({super.key, this.announcement});

  final Announcement? announcement;

  @override
  State<AnnouncementEditPage> createState() => _AnnouncementEditPageState();
}

class _AnnouncementEditPageState extends State<AnnouncementEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String _type;
  bool _loadingDetail = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement?.title);
    _contentController = TextEditingController(
      text: widget.announcement?.content,
    );
    _type = widget.announcement?.type ?? 'NEWS';
    if (widget.announcement != null && widget.announcement!.content == null) {
      _loadDetail();
    }
  }

  Future<void> _loadDetail() async {
    setState(() => _loadingDetail = true);
    try {
      final announcement = await AnnouncementService.fetchAnnouncement(
        widget.announcement!.id,
      );
      if (!mounted) return;
      _titleController.text = announcement.title;
      _contentController.text = announcement.content ?? '';
      setState(() => _type = announcement.type);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('公告详情加载失败，请重新进入编辑')));
      }
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save(String status) async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写公告标题和正文')));
      return;
    }
    setState(() => _saving = true);
    try {
      await AnnouncementService.saveAnnouncement(
        id: widget.announcement?.id,
        title: title,
        content: content,
        type: _type,
        status: status,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存失败，请稍后重试')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.announcement != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(isEditing ? '编辑公告内容' : '发布新公告'),
        actions: [
          TextButton(
            onPressed: _saving || _loadingDetail ? null : () => _save('DRAFT'),
            child: const Text('存草稿'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('公告标题', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                maxLength: 60,
                decoration: _inputDecoration('请输入公告标题'),
              ),
              const SizedBox(height: 12),
              const Text('公告类型', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey(_type),
                initialValue: _type,
                decoration: _inputDecoration(null),
                items: const [
                  DropdownMenuItem(value: 'NEWS', child: Text('校园资讯')),
                  DropdownMenuItem(value: 'HEALTH', child: Text('健康护理')),
                  DropdownMenuItem(value: 'FEEDING', child: Text('投喂指南')),
                  DropdownMenuItem(value: 'BEHAVIOR', child: Text('行为科普')),
                ],
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 12),
              const Text('正文内容', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: _inputDecoration('请输入公告正文'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _saving || _loadingDetail
                      ? null
                      : () => _save('PUBLISHED'),
                  child: Text(_saving ? '提交中...' : '立即发布公告'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String? hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  counterText: '',
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
);
