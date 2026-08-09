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

const campusMap = {
  "0": "中心校区",
  "1": "趵突泉校区",
  "2": "洪家楼校区",
  "3": "千佛山校区",
  "4": "兴隆山校区",
  "5": "软件园校区",
  "6": "青岛校区",
  "7": "威海校区",
  "8": "龙山校区",
};

/// 根据校区 code / 名称 获取中文名
String campusLabel(dynamic value) {
  if (value is num) {
    return campusMap[value.toInt().toString()] ?? '校区 ${value.toInt()}';
  }
  final str = value?.toString() ?? '';
  if (str.isEmpty) return '';
  return str;
}
