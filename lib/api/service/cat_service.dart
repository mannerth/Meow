import 'package:meow/api/data_response.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/cat.dart';
import 'package:meow/model/cat_detail.dart';
import 'package:meow/model/moment.dart';

class CatService {
  static Future<DataResponse<CatPage>> fetchCats({
    int page = 1,
    int pageSize = 20,
    String? campus,
    String? status,
    String? color,
    String? search,
    String? sort,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (campus != null && campus.isNotEmpty) params['campus'] = campus;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (color != null && color.isNotEmpty) params['color'] = color;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (sort != null && sort.isNotEmpty) params['sort'] = sort;

    final response = await Http().get(
      '/cats',
      queryParameters: params,
    );

    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(
      json,
      (object) => CatPage.fromJson(object as Map<String, dynamic>),
    );
  }

  static Future<DataResponse<CatDetail>> fetchCatDetail(String id) async {
    final response = await Http().get('/cats/$id');
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(
      json,
      (object) => CatDetail.fromJson(object as Map<String, dynamic>),
    );
  }

  static Future<DataResponse<MomentPage>> fetchCatMoments({
    required String catId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await Http().get(
      '/moments',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        'catId': catId,
      },
    );
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(
      json,
      (object) => MomentPage.fromJson(object as Map<String, dynamic>),
    );
  }

  static Future<DataResponse<MomentLikeResult>> likeMoment(
      String momentId) async {
    final response = await Http().post('/moments/$momentId/like');
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(
      json,
      (object) => MomentLikeResult.fromJson(object as Map<String, dynamic>),
    );
  }

  static Future<DataResponse<MomentLikeResult>> unlikeMoment(
      String momentId) async {
    final response = await Http().delete('/moments/$momentId/like');
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(
      json,
      (object) => MomentLikeResult.fromJson(object as Map<String, dynamic>),
    );
  }

  static Future<DataResponse<CatFeedResult>> feedCat(String id) async {
    final response = await Http().post('/cats/$id/feed');
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(
      json,
      (object) => CatFeedResult.fromJson(object as Map<String, dynamic>),
    );
  }

  static Future<DataResponse<String>> upsertCat({
    String? id,
    required Map<String, dynamic> payload,
  }) async {
    final response = id == null
        ? await Http().post('/admin/cats', data: payload)
        : await Http().put('/admin/cats/$id', data: payload);
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(
      json,
      (object) => (object as Map<String, dynamic>)['id'] as String,
    );
  }
}
