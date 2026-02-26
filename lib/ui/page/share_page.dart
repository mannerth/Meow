import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meow/api/http.dart';
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
  String? url;
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
          Image.network(  
            url ??
                '',
            width: 200,
            errorBuilder: (context, error, stackTrace) => Text('w'),
          ),
          ElevatedButton(
            onPressed: () async{
              final images = await ImagePicker().pickMultiImage(limit: 9);
              if( images.isEmpty ) return;
              // 连续上传有概率失败
              for( var img in images ){
                final resp = await Http().uploadImage(img);
                
                setState(() {
                  url = resp;
                });
              }
            }, 
            child: const Text('上传图片'),
          
          ),
        ],
      ),
    );
  }
}
