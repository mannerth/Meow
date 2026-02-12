import 'package:dio/dio.dart';
import 'package:meow/api/data_response.dart';
import 'package:meow/api/http.dart';

class UserService {

  static Future<Response<DataResponse>> sendCode(String email) async {
    //只用写相对路径
    return await Http().post<DataResponse>(
      '/users/send-verification-code',
      data: {
        'email':email
      }
    );
  }

}