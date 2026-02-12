
import 'package:flutter/foundation.dart';
import 'package:meow/api/data_response.dart';
import 'package:meow/model/user.dart';

void main(){

  DataResponse<dynamic> res = DataResponse.fromJson({
      'code':1,
      'data':{
        'id': '1',
        'studentId': '132',
      },
      'msg':""
    }
    //(i) => User.fromJson(i as Map<String, dynamic>)
  );

  // 如果自定义模型类，不写fromJson方法，可以像这样使用，作为Map取数据

  debugPrint('${res.data['id']}');

}