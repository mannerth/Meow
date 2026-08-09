/// 时间工具类
class TimeTool {
  /// 展示时间字符串
  /// 根据传入的日期时间，返回一个友好的时间表达字符串
  /// 例如："刚刚", "5分钟前", "昨天 14:30", "2023-04-01 12:00"
  static String getExpressionTimeString(DateTime datetime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(datetime);

    if (difference.inSeconds < 60) {
      return '刚刚';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    }
    if (difference.inDays == 1) {
      return '昨天 ${datetime.hour.toString()}:${datetime.minute.toString().padLeft(2, '0')}';
    }
    if (datetime.year == now.year) {
      return '${datetime.month.toString()}-${datetime.day.toString()} ${datetime.hour.toString()}:${datetime.minute.toString().padLeft(2, '0')}';
    }

    return datetime.toString().substring(0, 16);
  }

  static final List<String> names = ['一', '二', '三', '四', '五', '六', '日'];

  /// 根据数字获取对应的星期名称
  static String getWeekdayName(int weekday) {
    return names[(weekday - 1) % 7];
  }

  /// 将秒数转换为 "HH:MM:SS" 格式的字符串
  static String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final hoursStr = hours.toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');
    return '$hoursStr:$minutesStr:$secondsStr';
  }
}
