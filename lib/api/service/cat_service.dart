import 'package:dio/dio.dart';
import 'package:meow/api/data_response.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/cat.dart';
import 'package:meow/model/cat_detail.dart';
import 'package:meow/model/leaderboard.dart';
import 'package:meow/model/post.dart';

class CatService {
  static Future<DataResponse<CatPage>> fetchCats({
    int page = 1,
    int pageSize = 20,
    int? campus,
    int? status,
    int? color,
    String? search,
    String? sort,
  }) async {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (campus != null) params['campus'] = campus;
    if (status != null) params['status'] = status;
    if (color != null) params['color'] = color;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (sort != null && sort.isNotEmpty) params['sort'] = sort;

    final response = await Http().get('/cats', queryParameters: params);

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

  static Future<DataResponse<PostPage>> fetchCatPosts({
    required String catId,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await Http().get(
      '/posts',
      queryParameters: {'page': page, 'pageSize': pageSize, 'catId': catId},
    );
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(
      json,
      (object) => PostPage.fromJson(object as Map<String, dynamic>),
    );
  }

  static Future<DataResponse<PostLikeResult>> likePost(String postId) async {
    final response = await Http().post('/posts/$postId/like');
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(
      json,
      (object) => PostLikeResult.fromJson(object as Map<String, dynamic>),
    );
  }

  static Future<DataResponse<PostLikeResult>> unlikePost(String postId) async {
    final response = await Http().delete('/posts/$postId/like');
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(
      json,
      (object) => PostLikeResult.fromJson(object as Map<String, dynamic>),
    );
  }

  static Future<DataResponse<void>> deletePost(String postId) async {
    final response = await Http().delete('/posts/$postId');
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(json, (_) {});
  }

  static Future<DataResponse<void>> publishPost({
    required String content,
    List<String> media = const [],
    String? catId,
    String? location,
  }) async {
    final payload = <String, dynamic>{
      'content': content,
      'media': media,
      if (catId != null && catId.isNotEmpty) 'catId': catId,
      if (location != null && location.isNotEmpty) 'location': location,
    };
    final response = await Http().post('/posts', data: payload);
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(json, (_) {});
  }

  static Future<DataResponse<LeaderboardResponse>> fetchLeaderboard({
    required String type,
    int limit = 20,
  }) async {
    final response = await Http().get(
      '/leaderboard/$type',
      queryParameters: {'limit': limit},
    );
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(
      json,
      (object) => LeaderboardResponse.fromJson(object as Map<String, dynamic>),
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
    final formData = FormData.fromMap(payload);
    final response = id == null
        ? await Http().post(
            '/admin/cats',
            data: formData,
            options: Options(contentType: 'multipart/form-data'),
          )
        : await Http().put(
            '/admin/cats/$id',
            data: formData,
            options: Options(contentType: 'multipart/form-data'),
          );
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(json, (object) {
      if (object is String) return object;
      if (object is Map<String, dynamic>) {
        return (object['id'] ?? '').toString();
      }
      return '';
    });
  }

  static Future<DataResponse<void>> deleteCat(String id) async {
    final response = await Http().delete('/admin/cats/$id');
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(json, (_) {});
  }
}
