import 'package:flutter/material.dart';
import 'package:meow/api/service/adoption_service.dart';
import 'package:meow/model/adoption.dart';
import 'package:meow/model/static_type.dart';
import 'package:meow/ui/widget/safe_network_image.dart';
import 'package:meow/util/time_tool.dart';

class AdminAdoptionDetailPage extends StatefulWidget {
  final AdminAdoptionItem item;

  const AdminAdoptionDetailPage({super.key, required this.item});

  @override
  State<AdminAdoptionDetailPage> createState() =>
      _AdminAdoptionDetailPageState();
}

class _AdminAdoptionDetailPageState extends State<AdminAdoptionDetailPage> {
  late AdminAdoptionItem _item;
  final TextEditingController _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _audit(AdoptionStatus status) async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      _showMessage('请填写审核说明');
      return;
    }
    setState(() => _submitting = true);
    try {
      await AdoptionService.auditAdoption(
        id: _item.id,
        status: status,
        reason: reason,
      );
      if (!mounted) return;
      setState(() {
        _item = _item.copyWith(status: status);
      });
      _showMessage(status == AdoptionStatus.rejected ? '已拒绝该申请' : '审核状态已更新');
      Navigator.of(context).pop(_item);
    } catch (error) {
      _showMessage('提交失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final timeText = _formatTime(_item.createTime);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: Text(_item.id)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _ApplicantCard(item: _item, timeText: timeText),
          const SizedBox(height: 16),
          _CatCard(item: _item),
          const SizedBox(height: 16),
          _DetailCard(item: _item),
          const SizedBox(height: 18),
          _SectionTitle(title: '审核说明'),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '请输入审核原因/备注',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _submitting
                      ? null
                      : () => _audit(AdoptionStatus.rejected),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE5E5),
                    foregroundColor: const Color(0xFFCC3D3D),
                  ),
                  child: const Text('拒绝'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submitting
                      ? null
                      : () => _audit(AdoptionStatus.approved),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE4F4E8),
                    foregroundColor: const Color(0xFF2E7D32),
                  ),
                  child: const Text('通过'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _submitting
                  ? null
                  : () => _audit(AdoptionStatus.interview),
              child: const Text('要求补充材料 / 安排面谈'),
            ),
          ),
        ],
      ),
    );
  }

  String? _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return TimeTool.getExpressionTimeString(parsed);
  }
}

class _ApplicantCard extends StatelessWidget {
  final AdminAdoptionItem item;
  final String? timeText;

  const _ApplicantCard({required this.item, required this.timeText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage:
                    item.userAvatar != null && item.userAvatar!.isNotEmpty
                    ? NetworkImage(item.userAvatar!)
                    : null,
                child: item.userAvatar == null || item.userAvatar!.isEmpty
                    ? Text(item.userName.isNotEmpty ? item.userName[0] : '？')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.userName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.userCollege ?? item.userCampus ?? '信息未完善',
                      style: const TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
              _StatusChip(status: item.status),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: '学号', value: item.userStudentId ?? '—'),
          _InfoRow(label: '联系方式', value: item.contact?.phone ?? '—'),
          _InfoRow(label: '微信号', value: item.contact?.wechat ?? '—'),
          if (timeText != null) _InfoRow(label: '申请时间', value: timeText!),
        ],
      ),
    );
  }
}

class _CatCard extends StatelessWidget {
  final AdminAdoptionItem item;

  const _CatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SafeNetworkImage(
            url: item.catAvatar,
            width: 64,
            height: 64,
            borderRadius: BorderRadius.circular(12),
            placeholder: Container(
              width: 64,
              height: 64,
              color: const Color(0xFFE5E7EB),
              alignment: Alignment.center,
              child: const Icon(Icons.pets, color: Color(0xFF9CA3AF)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.catName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  item.userCampus ?? '校区未知',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFE2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '待领养',
              style: TextStyle(color: Color(0xFFE58B3A)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final AdminAdoptionItem item;

  const _DetailCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final info = item.info;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: '申请详情'),
          const SizedBox(height: 10),
          _InfoRow(label: '居住情况', value: adoptionHousingLabel(info?.housing)),
          _InfoRow(label: '养猫经验', value: _experienceLabel(info?.experience)),
          _InfoRow(label: '目前宠物', value: info == null ? '—' : '无'),
          if (info?.plan != null && info!.plan.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4DD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                info.plan,
                style: const TextStyle(color: Color(0xFF7A5A2C)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _experienceLabel(String? value) {
    switch (value) {
      case 'NEWBIE':
        return '新手';
      case 'EXPERIENCED':
        return '有经验';
      case 'MULTI_CAT':
        return '多猫家庭';
      default:
        return '—';
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AdoptionStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = _labelForStatus(status);
    final color = _colorForStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _labelForStatus(AdoptionStatus status) {
    switch (status) {
      case AdoptionStatus.interview:
        return '待补充';
      case AdoptionStatus.approved:
        return '已通过';
      case AdoptionStatus.rejected:
        return '已拒绝';
      case AdoptionStatus.completed:
        return '已完成';
      default:
        return '待审核';
    }
  }

  Color _colorForStatus(AdoptionStatus status) {
    switch (status) {
      case AdoptionStatus.interview:
        return const Color(0xFFF4A43A);
      case AdoptionStatus.approved:
        return const Color(0xFF43A047);
      case AdoptionStatus.rejected:
        return const Color(0xFFE14B4B);
      case AdoptionStatus.completed:
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFFF4A43A);
    }
  }
}
