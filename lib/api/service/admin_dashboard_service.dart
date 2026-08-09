import 'package:meow/api/data_response.dart';
import 'package:meow/api/http.dart';
import 'package:meow/model/admin_dashboard_stats.dart';

class AdminDashboardService {
  static Future<DataResponse<AdminDashboardStats>> fetchStats() async {
    final response = await Http().get('/admin/dashboard/stats');
    final json = response.data as Map<String, dynamic>;
    return DataResponse.fromJson(json, (object) => _parseStats(object));
  }

  static AdminDashboardStats _parseStats(Object? object) {
    if (object is Map<String, dynamic>) {
      return AdminDashboardStats.fromJson(object);
    }
    return AdminDashboardStats(
      pendingSos: 0,
      adoptApplications: 0,
      totalCats: 0,
      pendingNewCatClues: 0,
      campusDistribution: const [],
    );
  }
}
