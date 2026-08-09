import 'package:meow/api/data_response.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/admin_sos.dart';
import 'package:meow/model/user.dart';

class AdminSosService {
  static Future<DataResponse<AdminSosListPage>> fetchSosList({
    int page = 1,
    int size = 20,
    String? status,
    Campus? campus,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    if (campus != null) {
      params['campus'] = campus.apiKey;
    }

    final response = await Http().get('/admin/sos', queryParameters: params);
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(json, (object) => _parseListPage(object));
  }

  static Future<DataResponse<void>> resolveSos({
    required String id,
    required String status,
    required String reply,
  }) async {
    final payload = <String, dynamic>{'status': status, 'reply': reply};
    final response = await Http().post('/admin/sos/$id/resolve', data: payload);
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(json, (_) {});
  }

  static AdminSosListPage _parseListPage(Object? object) {
    if (object is Map<String, dynamic>) {
      return AdminSosListPage.fromJson(object);
    }
    return AdminSosListPage(total: 0, items: []);
  }
}
