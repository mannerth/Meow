/// 一般工具类
class CommonTool {

  /// 把数字转换成显示友好的字符串
  /// 
  /// value 整数值，
  /// maxCharacters 允许的最大字符数，默认4 
  ///  
  /// 尽量返回一个长度不超过maxCharacters的字符串，如123, 1k, 1.2w, 1.34m等
  static String getDisplayStringForInteger(int value, {int maxCharacters = 4}) {
    String str = value.toString();
    if (str.length <= maxCharacters) {
      return str;
    }
    if (maxCharacters <= 0) return '';

    final sign = value < 0 ? '-' : '';
    final absValue = value.abs();

    final List<Map<String, dynamic>> units = [
      {'value': 1000000000000, 'symbol': 't'},
      {'value': 1000000000, 'symbol': 'b'},
      {'value': 1000000, 'symbol': 'm'},
      {'value': 10000, 'symbol': 'w'}, // 万
      {'value': 1000, 'symbol': 'k'},
      {'value': 1, 'symbol': ''},
    ];

    // 找到第一个满足 absValue >= unit.value 的单位（从大到小遍历）
    int idx = units.length - 1;
    for (int i = 0; i < units.length; i++) {
      if (absValue >= units[i]['value']) {
        idx = i;
        break;
      }
    }

    // 计算可供数字部分使用的字符数（扣除单位和符号）
    int availableForNumber = maxCharacters - sign.length - (units[idx]['symbol'] as String).length;
    if (availableForNumber <= 0) {
      // 太短时退回到直接截断原始数字（保留符号位置）
      return str.substring(0, maxCharacters);
    }

    double scaled() => absValue / (units[idx]['value'] as num);

    // 如果整数部分太长，尝试使用更大的单位（往上走列表）
    while (true) {
      double s = scaled();
      int intDigits = s >= 1 ? s.floor().toString().length : 1;
      if (intDigits <= availableForNumber) break;
      // 尝试上一个（更大）单位
      if (idx == 0) break; // 已经是最大的单位，不能再上升
      idx = idx - 1;
      availableForNumber = maxCharacters - sign.length - (units[idx]['symbol'] as String).length;
      if (availableForNumber <= 0) {
        return str.substring(0, maxCharacters);
      }
    }

    // 现在准备格式化：尽量多保留小数位但不超长
    double s = scaled();
    int intDigits = s >= 1 ? s.floor().toString().length : 1;
    int decimals = 0;
    if (availableForNumber > intDigits) {
      // 需要留一个位置给小数点，再剩余的位置给小数位
      int possible = availableForNumber - intDigits - 1;
      decimals = possible > 0 ? possible : 0;
    }

    // 格式化时可能出现四舍五入导致整数位增多（例如 9.99 -> 10.0），需要检测并回退小数位
    String fmt;
    while (true) {
      fmt = s.toStringAsFixed(decimals);
      // 去掉多余的尾零和末尾的小数点
      if (fmt.contains('.')) {
        fmt = fmt.replaceAll(RegExp(r'0+$'), '');
        fmt = fmt.replaceAll(RegExp(r'\.$'), '');
      }
      if (fmt.length <= availableForNumber) {
        break;
      }
      if (decimals > 0) {
        decimals -= 1;
        continue;
      } else {
        // 无法通过减少小数位适配，退回截断原始数字（保守策略）
        return str.substring(0, maxCharacters);
      }
    }

    return sign + fmt + (units[idx]['symbol'] as String);
  }
}