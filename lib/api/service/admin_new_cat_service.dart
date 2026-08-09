import 'package:meow/api/data_response.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/admin_new_cat.dart';

class AdminNewCatService {
  static Future<DataResponse<AdminNewCatListPage>> fetchNewCats({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }

    final response = await Http().get(
      '/admin/new-cats',
      queryParameters: params,
    );
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(json, (object) => _parseListPage(object));
  }

  static Future<DataResponse<void>> approveNewCat({
    required String id,
    required String officialName,
  }) async {
    final payload = <String, dynamic>{'officialName': officialName};
    final response = await Http().post(
      '/admin/new-cats/$id/approve',
      data: payload,
    );
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(json, (_) {});
  }

  static AdminNewCatListPage _parseListPage(Object? object) {
    if (object is Map<String, dynamic>) {
      return AdminNewCatListPage.fromJson(object);
    }
    return AdminNewCatListPage(total: 0, items: []);
  }
}
