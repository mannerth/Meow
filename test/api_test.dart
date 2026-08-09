import 'package:flutter_test/flutter_test.dart';
import 'package:meow/api/data_response.dart';

void main() {
  test('DataResponse 解析 Map 数据', () {
    final res = DataResponse.fromJson({
      'code': 1,
      'data': {'id': '1', 'studentId': '132'},
      'msg': '',
    });

    expect(res.data['id'], '1');
  });
}
