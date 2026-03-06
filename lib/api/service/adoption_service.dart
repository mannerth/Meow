import 'package:meow/api/data_response.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/adoption.dart';

class AdoptionService {
  static Future<DataResponse<void>> submitAdoption({
    required String catId,
    required AdoptionInfo info,
    required AdoptionContact contact,
  }) async {
    final payload = <String, dynamic>{
      'catId': catId,
      'info': info.toJson(),
      'contact': contact.toJson(),
    };
    final response = await Http().post('/adoptions', data: payload);
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(json, (_) {});
  }

  static Future<DataResponse<AdminAdoptionListPage>> fetchAdminAdoptions({
    int page = 1,
    int size = 20,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    final response = await Http().get(
      '/admin/adoptions',
      queryParameters: params,
    );
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(
      json,
      (object) => _parseAdminList(object),
    );
  }

  static Future<DataResponse<void>> auditAdoption({
    required String id,
    required String status,
    required String reason,
  }) async {
    final payload = <String, dynamic>{
      'status': status,
      'reason': reason,
    };
    final response = await Http().post(
      '/admin/adoptions/$id/audit',
      data: payload,
    );
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(json, (_) {});
  }

  static Future<DataResponse<UserAdoptionListPage>> fetchMyAdoptions({
    int page = 1,
    int size = 20,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    final response = await Http().get(
      '/adoptions/my',
      queryParameters: params,
    );
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(
      json,
      (object) => _parseUserList(object),
    );
  }

  static AdminAdoptionListPage _parseAdminList(Object? object) {
    if (object is Map<String, dynamic>) {
      return AdminAdoptionListPage.fromJson(object);
    }
    return AdminAdoptionListPage(total: 0, items: []);
  }

  static UserAdoptionListPage _parseUserList(Object? object) {
    if (object is Map<String, dynamic>) {
      return UserAdoptionListPage.fromJson(object);
    }
    return UserAdoptionListPage(total: 0, items: []);
  }
}
