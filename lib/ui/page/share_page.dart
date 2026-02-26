import 'package:flutter/material.dart';
import 'package:meow/api/service/auth_repository.dart';
import 'package:meow/ui/page/cat_select_page.dart';

/// 发布动态页面
class SharePage extends StatefulWidget {
  const SharePage({super.key});

  @override
  State<SharePage> createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  String? _selectedCatId;

  Future<void> _selectCat() async {
    final selectedId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CatSelectPage(selectable: true)),
    );
    if (selectedId == null) return;
    setState(() {
      _selectedCatId = selectedId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _selectCat,
            child: const Text('选择猫咪'),
          ),
          const SizedBox(height: 12),
          Text(_selectedCatId == null ? '未选择猫咪' : '已选择: $_selectedCatId'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              AuthRepository.getMe();
            },
            child: const Text('测试'),
          ),
        ],
      ),
    );
  }
}
