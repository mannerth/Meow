import 'package:flutter_test/flutter_test.dart';
import 'package:meow/api/data_response.dart';
import 'package:meow/model/admin_new_cat.dart';
import 'package:meow/model/user.dart';

void main() {
  test('DataResponse 解析 Map 数据', () {
    final res = DataResponse.fromJson({
      'code': 1,
      'data': {'id': '1', 'studentId': '132'},
      'msg': '',
    });

    expect(res.data['id'], '1');
  });

  test('用户资料缺少展示字段时使用默认值', () {
    final user = User.fromJson({'uid': 4, 'nickname': '测试用户', 'campus': 0});

    expect(user.studentId, '');
    expect(user.currency, 0);
    expect(user.level, 0);
    expect(user.experience, 0);
    expect(user.nextLevelExp, 0);
    expect(user.campus, Campus.zhongxin);
  });

  test('新猫图片对象解析为可加载的 url', () {
    final item = AdminNewCatItem.fromJson({
      'id': 'new-cat-1',
      'status': 'PENDING',
      'imageURLs': [
        {
          'key': 'meow/4/2026-08-14/example.jpg',
          'url': 'https://example.com/meow/4/2026-08-14/example.jpg',
        },
      ],
    });

    expect(item.images, ['https://example.com/meow/4/2026-08-14/example.jpg']);
  });
}
