import 'package:meow/api/data_response.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/notification.dart';
import 'package:meow/model/static_type.dart';

class AnnouncementService {
  static Future<Announcement> fetchAnnouncement(String id) async {
    final response = await Http().get('/announcements/$id');
    final result = DataResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Announcement.fromJson(data as Map<String, dynamic>),
    );
    return result.data!;
  }

  static Future<DataResponse<AnnouncementPage>> fetchAdminAnnouncements({
    int page = 1,
    int pageSize = 20,
    AnnouncementStatus? status,
  }) async {
    final response = await Http().get(
      '/admin/announcements',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'status': ?status?.code,
      },
    );
    return DataResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AnnouncementPage.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<void> saveAnnouncement({
    String? id,
    required String title,
    required String content,
    required AnnouncementType type,
    required AnnouncementStatus status,
  }) async {
    final payload = {
      'title': title,
      'content': content,
      'summary': content.length > 80 ? content.substring(0, 80) : content,
      'type': type.code,
      'status': status.code,
    };
    if (id == null) {
      await Http().post('/admin/announcements', data: payload);
    } else {
      await Http().put('/admin/announcements/$id', data: payload);
    }
  }

  static Future<void> deleteAnnouncement(String id) async {
    await Http().delete('/admin/announcements/$id');
  }
}
