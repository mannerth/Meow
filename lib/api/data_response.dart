import 'package:json_annotation/json_annotation.dart';

part 'data_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class DataResponse<T> {
  int code;

  String msg;

  T? data;

  DataResponse({required this.code, required this.msg, this.data});

  factory DataResponse.fromJson(
    Map<String, dynamic> json, [
    T Function(Object?)? fromJsonT,
  ]) {
    if (fromJsonT != null) {
      return _$DataResponseFromJson(json, fromJsonT);
    } else {
      return DataResponse(
        code: (json['code'] as num).toInt(),
        msg: json['msg'] as String,
        data: json['data'],
      );
    }
  }

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$DataResponseToJson(this, toJsonT);
}
