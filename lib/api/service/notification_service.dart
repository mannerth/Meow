import 'package:meow/api/data_response.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/notification.dart';

class NotificationService {
  static Future<DataResponse<NotificationPage>> fetchNotifications({
    int page = 1,
    int pageSize = 20,
    String? type,
    bool? isRead,
  }) async {
    final response = await Http().get(
      '/notifications',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'type': ?type,
        'isRead': ?isRead,
      },
    );
    return DataResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => NotificationPage.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<void> markAsRead(String id) async {
    await Http().post('/notifications/$id/read');
  }

  static Future<void> markAllAsRead() async {
    await Http().post('/notifications/read-all');
  }
}
