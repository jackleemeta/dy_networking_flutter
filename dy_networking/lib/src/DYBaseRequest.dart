import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'DYRequestContentType.dart';
import 'NetClient.dart';
import 'DYResponse.dart';
import 'HTTPMethod.dart';

/// 基础request类
class DYBaseRequest {
  DYBaseRequest() {
    cancelToken = CancelToken();
  }

  String get baseUrl => "";

  String get path => "";

  String get method => HTTPMethod.GET;

  /// Header field name参考[Headers.contentTypeHeader]等
  Map<String, dynamic> get requestHeaders => {};

  Map<String, dynamic> get requestParamObject => {};

  Future<DYResponse> request() async {
    final dyResponse = await NetClient.request(path,
        baseUrl: baseUrl,
        headers: requestHeaders,
        data: _formattedRequestParamObjectContainedHTTPMethod,
        method: method,
        cancelToken: cancelToken);
    return dyResponse;
  }

  dynamic get formattedRequestParamObject {
    dynamic aDynamic;
    try {
      final contentType = requestHeaders[Headers.contentTypeHeader] ??
          DYRequestContentType.application_json;

      switch (contentType) {
        case DYRequestContentType.application_json:
          aDynamic = jsonEncode(requestParamObject);
          break;
        case DYRequestContentType.multipart_form_data:
          aDynamic = FormData.fromMap(requestParamObject);
          break;
        default:
          aDynamic = requestParamObject;
          break;
      }
    } catch (error) {
      aDynamic = requestParamObject;
      debugPrint("DYBaseRequest formattedRequestParamObject error = $error");
    }

    return aDynamic;
  }

  CancelToken cancelToken;

  void cancel() => NetClient.cancelRequests(cancelToken);

  /// -------------------------------------------- Private API --------------------------------------------

  dynamic get _formattedRequestParamObjectContainedHTTPMethod {
    dynamic aDynamic;
    switch (method) {
      case HTTPMethod.GET:
        aDynamic = requestParamObject;
        break;
      default:
        aDynamic = formattedRequestParamObject;
        break;
    }
    return aDynamic;
  }
}
