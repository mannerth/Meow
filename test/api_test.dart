import 'package:flutter_test/flutter_test.dart';
import 'package:meow/api/data_response.dart';
import 'package:meow/api/service/cat_service.dart';
import 'package:meow/model/admin_new_cat.dart';
import 'package:meow/model/admin_sos.dart';
import 'package:meow/model/adoption.dart';
import 'package:meow/model/cat.dart';
import 'package:meow/model/cat_detail.dart';
import 'package:meow/model/leaderboard.dart';
import 'package:meow/model/static_type.dart';
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

  test('管理员猫咪图片接口从对象中提取持久 key', () {
    final keys = CatImageKeys.fromJson({
      'avatar': {
        'key': 'meow/4/2026-08-14/avatar.jpg',
        'url': 'https://example.com/avatar.jpg',
      },
      'images': [
        {
          'key': 'meow/4/2026-08-14/image.jpg',
          'url': 'https://example.com/image.jpg',
        },
      ],
    });

    expect(keys.avatar, 'meow/4/2026-08-14/avatar.jpg');
    expect(keys.images, ['meow/4/2026-08-14/image.jpg']);
  });

  test('SOS 整数状态解析为强类型枚举', () {
    final item = AdminSosItem.fromJson({'id': 'sos-1', 'status': 1});

    expect(item.status, SosStatus.processing);
    expect(item.status.code, 1);
    expect(item.status.apiName, 'PROCESSING');
  });

  test('领养整数状态解析和请求编码正确', () {
    final item = AdminAdoptionItem.fromJson({
      'id': 'adoption-1',
      'catId': 'cat-1',
      'catName': '小白',
      'status': 0,
    });

    expect(item.status, AdoptionStatus.pending);
    expect(item.status.code, 0);
    expect(AdoptionStatus.rejected.code, 3);
  });

  test('猫咪列表整数类型保留 ID 且不直接展示数字字符串', () {
    final cat = Cat.fromJson({
      'id': 'cat-1',
      'name': '小白',
      'avatar': '',
      'color': 4,
      'campus': 1,
      'location': 3,
      'role': 5,
      'status': 0,
    });

    expect(cat.colorId, 4);
    expect(cat.locationId, 3);
    expect(cat.roleId, 5);
    expect(cat.color, isEmpty);
    expect(cat.locationName, isEmpty);
    expect(cat.roleName, isEmpty);
  });

  test('固定枚举集中处理整数与旧字符串响应', () {
    expect(CatGender.fromApi(2), CatGender.female);
    expect(CatGender.fromApi('MALE'), CatGender.male);
    expect(CatStatus.fromApi('住院').code, 3);
    expect(CatNeuteredType.fromApi('UNCUT').code, 1);
    expect(CatHealthStatus.fromApi('RECOVERING').code, 2);
  });

  test('猫咪固定字段存为枚举并按整数序列化', () {
    final detail = CatDetail.fromJson(<String, dynamic>{
      'id': 'cat-1',
      'name': '小白',
      'basicInfo': <String, dynamic>{
        'color': 6,
        'gender': 2,
        'campus': 0,
        'status': 3,
        'healthStatus': 1,
        'neutered': <String, dynamic>{'type': 0},
      },
      'attributes': <String, dynamic>{},
    });

    expect(detail.basicInfo.gender, CatGender.female);
    expect(detail.basicInfo.color, '6');
    expect(detail.basicInfo.campus, Campus.zhongxin);
    expect(detail.basicInfo.status, CatStatus.hospitalized);
    expect(detail.basicInfo.healthStatus, CatHealthStatus.sick);
    expect(detail.basicInfo.neutered.type, CatNeuteredType.earCut);
    expect(detail.basicInfo.toJson()['gender'], 2);
    expect(detail.basicInfo.toJson()['campus'], 0);
    expect(detail.basicInfo.toJson()['status'], 3);
  });

  test('权限角色使用新版整数编码', () {
    final user = User.fromJson({'uid': 4, 'roleType': 2});

    expect(user.roleType, RoleType.superAdmin);
    expect(user.isAdmin, isTrue);
    expect(user.toJson()['roleType'], 2);
  });

  test('排行榜兼容整数校区和标签 ID', () {
    final item = LeaderboardItem.fromJson({
      'rank': 1,
      'catId': 'cat-1',
      'name': '小白',
      'campus': 0,
      'value': 9.5,
      'tags': [
        3,
        {'id': 4},
      ],
    });

    expect(item.campus, '中心校区');
    expect(item.tags, ['3', '4']);
    expect(item.value, 9.5);
  });
}
