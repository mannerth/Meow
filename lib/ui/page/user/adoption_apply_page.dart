import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/api/service/adoption_service.dart';
import 'package:meow/model/adoption.dart';
import 'package:meow/model/cat.dart';
import 'package:meow/provider/auth_provider.dart';
import 'package:meow/ui/page/user/cat_select_page.dart';
import 'package:meow/ui/widget/safe_network_image.dart';

class AdoptionApplyPage extends ConsumerStatefulWidget {
  final Cat? initialCat;

  const AdoptionApplyPage({super.key, this.initialCat});

  @override
  ConsumerState<AdoptionApplyPage> createState() => _AdoptionApplyPageState();
}

class _AdoptionApplyPageState extends ConsumerState<AdoptionApplyPage> {
  final TextEditingController _planController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _wechatController = TextEditingController();

  Cat? _selectedCat;
  String? _selectedHousing;
  String? _selectedExperience;
  bool _agreed = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCat = widget.initialCat;
  }

  @override
  void dispose() {
    _planController.dispose();
    _phoneController.dispose();
    _wechatController.dispose();
    super.dispose();
  }

  Future<void> _selectCat() async {
    final selected = await Navigator.of(context).push<Cat>(
      MaterialPageRoute(builder: (_) => const CatSelectPage(selectable: true)),
    );
    if (selected == null) return;
    setState(() => _selectedCat = selected);
  }

  Future<void> _submit() async {
    final cat = _selectedCat;
    final housing = _selectedHousing;
    final experience = _selectedExperience;
    final plan = _planController.text.trim();
    final phone = _phoneController.text.trim();
    final wechat = _wechatController.text.trim();

    if (cat == null) {
      _showMessage('请选择领养对象');
      return;
    }
    if (housing == null || housing.isEmpty) {
      _showMessage('请选择居住情况');
      return;
    }
    if (experience == null || experience.isEmpty) {
      _showMessage('请选择养猫经验');
      return;
    }
    if (plan.isEmpty) {
      _showMessage('请填写申请理由与喂养计划');
      return;
    }
    if (phone.isEmpty || wechat.isEmpty) {
      _showMessage('请填写联系方式');
      return;
    }
    if (!_agreed) {
      _showMessage('请先阅读并同意领养协议');
      return;
    }

    setState(() => _submitting = true);
    try {
      await AdoptionService.submitAdoption(
        catId: cat.id,
        info: AdoptionInfo(
          housing: int.tryParse(housing),
          experience: experience,
          plan: plan,
        ),
        contact: AdoptionContact(phone: phone, wechat: wechat),
      );
      if (!mounted) return;
      _showMessage('申请已提交，请等待协会审核');
      _planController.clear();
      _phoneController.clear();
      _wechatController.clear();
      setState(() {
        _selectedHousing = null;
        _selectedExperience = null;
        _agreed = false;
        _selectedCat = null;
      });
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
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).user;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4ED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCE5C5),
        elevation: 0,
        title: const Text(
          '申请领养',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          const _ProgressHeader(),
          const SizedBox(height: 16),
          _SelectedCatCard(cat: _selectedCat, onTap: _selectCat),
          const SizedBox(height: 12),
          _TipCard(text: '温馨提示：学生宿舍严禁饲养宠物，请确保您有校外稳定住所。'),
          const SizedBox(height: 16),
          _SectionTitle(title: '目前的居住情况'),
          const SizedBox(height: 10),
          _OptionGrid(
            options: const [
              _OptionItem(label: '自有住房', value: '4'),
              _OptionItem(label: '整租', value: '3'),
              _OptionItem(label: '合租', value: '2'),
              _OptionItem(label: '与父母同住', value: '1'),
              _OptionItem(label: '校内宿舍', value: '0'),
            ],
            selectedValue: _selectedHousing,
            onChanged: (value) => setState(() => _selectedHousing = value),
          ),
          const SizedBox(height: 18),
          _SectionTitle(title: '养猫经验'),
          const SizedBox(height: 10),
          _OptionRow(
            options: const [
              _OptionItem(label: '新手', value: 'NEWBIE'),
              _OptionItem(label: '有经验', value: 'EXPERIENCED'),
              _OptionItem(label: '多猫家庭', value: 'MULTI_CAT'),
            ],
            selectedValue: _selectedExperience,
            onChanged: (value) => setState(() => _selectedExperience = value),
          ),
          const SizedBox(height: 18),
          _SectionTitle(title: '申请理由 & 喂养计划'),
          const SizedBox(height: 10),
          _TextCard(
            controller: _planController,
            hintText: '请简述您的经济状况、封闭计划以及对猫咪不离不弃的承诺…',
            maxLines: 5,
          ),
          const SizedBox(height: 18),
          _SectionTitle(title: '联系方式（微信号/手机号）'),
          const SizedBox(height: 10),
          _TextCard(
            controller: _phoneController,
            hintText: '手机号',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          _TextCard(controller: _wechatController, hintText: '微信号'),
          const SizedBox(height: 14),
          _AgreementRow(
            value: _agreed,
            onChanged: (value) => setState(() => _agreed = value ?? false),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '当前账号：${user.nickname ?? '同学'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8C7A63),
                ),
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF6C65B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                _submitting ? '提交中...' : '提交申请',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5D3D12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEAD1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('领养流程', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 10),
          _StepRow(),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow();

  @override
  Widget build(BuildContext context) {
    final steps = ['填写资料', '协会审核', '线下面谈', '接猫回家'];
    return Row(
      children: List.generate(
        steps.length,
        (index) => Expanded(
          child: Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: index == 0 ? const Color(0xFFF6C65B) : Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFF6C65B)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 6),
              Text(steps[index], style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedCatCard extends StatelessWidget {
  final Cat? cat;
  final VoidCallback onTap;

  const _SelectedCatCard({required this.cat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            SafeNetworkImage(
              url: cat?.avatar,
              width: 56,
              height: 56,
              borderRadius: BorderRadius.circular(12),
              placeholder: Container(
                width: 56,
                height: 56,
                color: const Color(0xFFF2F3F5),
                alignment: Alignment.center,
                child: const Icon(Icons.pets, color: Color(0xFFB7B7B7)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat?.name ?? '当前申请对象',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat?.locationName ?? '点击选择猫咪',
                    style: const TextStyle(color: Color(0xFF8C7A63)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F5E3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                cat == null ? '请选择' : '已选择',
                style: const TextStyle(
                  color: Color(0xFF3D7F3A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;

  const _TipCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEBFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Color(0xFF3B6FD0), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF3B6FD0), fontSize: 12),
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
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _OptionItem {
  final String label;
  final String value;

  const _OptionItem({required this.label, required this.value});
}

class _OptionGrid extends StatelessWidget {
  final List<_OptionItem> options;
  final String? selectedValue;
  final ValueChanged<String> onChanged;

  const _OptionGrid({
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: options
          .map(
            (item) => _ChoiceChip(
              label: item.label,
              selected: selectedValue == item.value,
              onTap: () => onChanged(item.value),
            ),
          )
          .toList(),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final List<_OptionItem> options;
  final String? selectedValue;
  final ValueChanged<String> onChanged;

  const _OptionRow({
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    for (var i = 0; i < options.length; i++) {
      final item = options[i];
      widgets.add(
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == options.length - 1 ? 0 : 10),
            child: _ChoiceChip(
              label: item.label,
              selected: selectedValue == item.value,
              onTap: () => onChanged(item.value),
            ),
          ),
        ),
      );
    }
    return Row(children: widgets);
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3D3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFF6C65B) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF6B4B11) : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final int maxLines;

  const _TextCard({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _AgreementRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: onChanged),
        const Expanded(
          child: Text(
            '我已阅读并同意《山大猫猫领养协议》，承诺科学喂养，适龄绝育，有病就医，接受定期回访，绝不遗弃。',
            style: TextStyle(fontSize: 12, color: Color(0xFF7A6A55)),
          ),
        ),
      ],
    );
  }
}
