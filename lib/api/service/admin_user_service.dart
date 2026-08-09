import 'package:meow/api/data_response.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/admin_user.dart';
import 'package:meow/model/user.dart';

class AdminUserService {
  static Future<DataResponse<AdminUserListPage>> fetchUsers({
    int page = 1,
    int size = 20,
    Campus? campus,
    String? search,
    String? permission,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (campus != null) {
      params['campus'] = campus.code;
    }
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    if (permission != null && permission.trim().isNotEmpty) {
      params['premission'] = permission.trim();
    }

    final response = await Http().get('/admin/users', queryParameters: params);
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(json, (object) => _parseListPage(object));
  }

  static Future<DataResponse<AdminUserDetail>> fetchUserDetail(
    String id,
  ) async {
    final response = await Http().get('/admin/users/$id');
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(json, (object) => _parseDetail(object, id));
  }

  static Future<DataResponse<void>> toggleBan(String id) async {
    final response = await Http().post('/admin/users/$id/ban');
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(json, (_) {});
  }

  static AdminUserListPage _parseListPage(Object? object) {
    if (object is Map<String, dynamic>) {
      return AdminUserListPage.fromJson(object);
    }
    if (object is List) {
      final items = object
          .whereType<Map<String, dynamic>>()
          .map(AdminUserListItem.fromJson)
          .toList();
      return AdminUserListPage(total: items.length, items: items);
    }
    return AdminUserListPage(total: 0, items: []);
  }

  static AdminUserDetail _parseDetail(Object? object, String id) {
    if (object is Map<String, dynamic>) {
      return AdminUserDetail.fromJson(object);
    }
    return AdminUserDetail(
      id: id,
      name: null,
      nickname: null,
      role: null,
      studentId: null,
      campusCode: null,
      campus: null,
      level: null,
      status: null,
      stats: AdminUserStats(
        feedCount: 0,
        foundCount: 0,
        receivedLikes: 0,
        momentCount: 0,
      ),
    );
  }
}
