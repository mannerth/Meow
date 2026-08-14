import 'package:meow/model/user.dart';

const campusList = [
  "中心校区",
  "趵突泉校区",
  "洪家楼校区",
  "千佛山校区",
  "兴隆山校区",
  "软件园校区",
  "青岛校区",
  "威海校区",
  "龙山校区",
];

/// 根据校区 code / 名称 获取中文名
String campusLabel(dynamic value) {
  if (value is num)
    return Campus.fromCode(value.toInt())?.name ?? '校区 ${value.toInt()}';
  final str = value?.toString() ?? '';
  final code = int.tryParse(str);
  if (code != null) return Campus.fromCode(code)?.name ?? '校区 $code';
  if (str.isEmpty) return '';
  return str;
}
