import 'dart:convert';
import 'dart:io';
import 'package:dy_networking/src/NetClientHeaders.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'DYResponse.dart';
import 'package:dio/adapter.dart';
import 'NetClientConfig.dart';

/*
 *
 * 网络请求过程处理中心
 * 
 */
const _sendTimeout = 30 * 1000; //毫秒
const _connectTimeout = 30 * 1000; //毫秒

class NetClient {
  /*
   * Request
   */
  static Future<DYResponse> request(path,
      {String baseUrl,
      Map<String, dynamic> headers,
      data,
      String method,
      CancelToken cancelToken}) async {
    final Dio dio = await _dio;
    await _fetchHeadersFor(baseUrl);

    await _configBaseOptions(baseUrl);

    DYResponse dyResponse;
    try {
      final options = Options();
      options.method = method;
      options.headers = headers;

      Response response;

      if (method == "GET") {
        response = await dio.request(path,
            queryParameters: data, options: options, cancelToken: cancelToken);
      } else if (method == "POST") {
        response = await dio.request(path,
            data: data, options: options, cancelToken: cancelToken);
      } else {
        response = await dio.request(path,
            data: data, options: options, cancelToken: cancelToken);
      }

      dyResponse = _process(response);
    } on DioError catch (error) {
      dyResponse = _formatError(error, baseUrl, path, data: data);
    }
    return dyResponse;
  }

  /*
   * Get
   */
  static Future<DYResponse> get(path,
      {String baseUrl,
      Map<String, dynamic> headers,
      Map<String, dynamic> queryParameters,
      CancelToken cancelToken}) async {
    final Dio dio = await _dio;

    await _fetchHeadersFor(baseUrl);

    await _configBaseOptions(baseUrl);

    DYResponse dyResponse;

    try {
      final options = Options();
      options.headers = headers;

      final response = await dio.get(path,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken);

      dyResponse = _process(response);
    } on DioError catch (error) {
      dyResponse = _formatError(error, baseUrl, path, data: queryParameters);
    }
    return dyResponse;
  }

  /*
   * Post
   */
  static Future<DYResponse> post(path,
      {String baseUrl,
      Map<String, dynamic> headers,
      data,
      CancelToken cancelToken}) async {
    final Dio dio = await _dio;

    await _fetchHeadersFor(baseUrl);

    await _configBaseOptions(baseUrl);

    DYResponse dyResponse;

    try {
      final options = Options();
      options.headers = headers;

      final response = await dio.post(path,
          data: data, options: options, cancelToken: cancelToken);

      dyResponse = _process(response);
    } on DioError catch (error) {
      dyResponse = _formatError(error, baseUrl, path, data: data);
    }
    return dyResponse;
  }

  /*
   * Download
   */
  static Future<DYResponse> downloadFile(urlPath, savePath, {baseUrl}) async {
    final Dio dio = await _dio;

    await _fetchHeadersFor(baseUrl);

    await _configBaseOptions(baseUrl);

    DYResponse dyResponse;
    try {
      Response response = await dio.download(urlPath, savePath,
          onReceiveProgress: (int count, int total) {
        debugPrint("$count $total");
      });
      dyResponse = _process(response);
    } on DioError catch (error) {
      dyResponse = _formatError(
        error,
        baseUrl,
        urlPath,
      );
    }
    return dyResponse;
  }

  /*
   * 取消请求
   *
   * 同一个cancel token 可以用于多个请求，当一个cancel token取消时，所有使用该cancel token的请求都会被取消。
   * 
   */
  static void cancelRequests(CancelToken token) {
    token.cancel("cancelled");
  }

  /// 设置headers
  ///
  /// [headers]
  /// [forBaseUrl] url
  static void setHeaders(Map headers, String forBaseUrl) {
    if (headers == null || headers.length == 0) {
      debugPrint("NetClient setHeaders 为空 headers = $headers");
      return;
    }

    var existedHeaders = _defaultHeadersForbaseUrl[forBaseUrl];
    if (existedHeaders == null) {
      existedHeaders = Map<String, dynamic>();
      _defaultHeadersForbaseUrl[forBaseUrl] = existedHeaders;
    }

    final castedHeaders = Map<String, dynamic>.from(headers);
    existedHeaders.addAll(castedHeaders);
  }

  /// 清理指定headers
  ///
  /// [baseUrl] headers所绑定的url
  static clearHeaderForBaseUrl(String baseUrl) async {
    final dio = await _dio;
    dio.options = null;

    _defaultHeadersForbaseUrl.remove(baseUrl);
  }

  /// 清理所有header
  static clearAllHeader() async {
    final dio = await _dio;

    dio.options = null;
    _defaultHeadersForbaseUrl.clear();
  }

  /// 设置Cookie
  ///
  /// [cookie] cookie
  /// [forBaseUrl] url
  static void setCookie(String cookie, String forBaseUrl) {
    if (cookie == null || cookie.length == 0) {
      debugPrint("NetClient setCookie 为空 cookie = $cookie");
      return;
    }

    var existedHeaders = _defaultHeadersForbaseUrl[forBaseUrl];
    if (existedHeaders == null) {
      existedHeaders = Map<String, dynamic>();
      _defaultHeadersForbaseUrl[forBaseUrl] = existedHeaders;
    }
    existedHeaders.addAll({_kTextCookie: cookie});
  }

  /// 清理指定cookie
  ///
  /// [baseUrl] cookie所绑定的url
  static clearCookieForBaseUrl(String baseUrl) async {
    Dio dio = await _dio;
    dio.options?.headers?.remove(_kTextCookie);

    final headers = _defaultHeadersForbaseUrl[baseUrl];
    headers?.remove(_kTextCookie);
  }

  /// 清理所有cookie
  static clearAllCookie() async {
    Dio dio = await _dio;
    dio.options?.headers?.remove(_kTextCookie);

    _defaultHeadersForbaseUrl.forEach((key, headers) {
      headers?.remove(_kTextCookie);
    });
  }

  /// ---------------------------- Private API ----------------------------

  static Dio _storedDio;

  static Map<String, Map<String, dynamic>> _defaultHeadersForbaseUrl = Map();

  static get _dio async {
    if (_storedDio != null) return _storedDio;

    _storedDio = Dio();

    if (NetClientConfig.isProxyMode) {
      //配置代理方案
      (_storedDio.httpClientAdapter as DefaultHttpClientAdapter)
          .onHttpClientCreate = (client) {
        client.findProxy = (uri) {
          // proxy all request to localhost:port
          // e.g. "PROXY 192.192.192.192:8888"
          return "PROXY ${NetClientConfig.localProxyHost}";
        };
      };
    }

    //配置默认Option
    _storedDio.options = BaseOptions(
        //default
        sendTimeout: _sendTimeout,
        connectTimeout: _connectTimeout);

    //配置请求过程拦截器
    _storedDio.interceptors
        .add(InterceptorsWrapper(onRequest: (RequestOptions options) {
      debugPrint("请求之前");
      return options;
    }, onResponse: (Response response) {
      debugPrint("响应之前");
      _processCookieForResponse(response);
      return response;
    }, onError: (DioError error) {
      debugPrint("错误之前");
    }));

    return _storedDio;
  }

  /*
   * _configBaseOptions
   */
  static _configBaseOptions(baseUrl) async {
    final Dio dio = await _dio;
    if (baseUrl == null) throw "baseUrl 为空";

    var anOptions = BaseOptions(
        baseUrl: baseUrl,
        sendTimeout: _sendTimeout,
        connectTimeout: _connectTimeout);

    try {
      final headers = _defaultHeadersForbaseUrl[baseUrl];
      if (headers != null) {
        anOptions.headers.addAll(headers);
      }
    } catch (error) {
      debugPrint("config BaseOptions headers error = $error");
    }

    dio.options = anOptions;
  }

  /// 获取 baseUrl header
  static _fetchHeadersFor(String baseUrl) async {
    if (baseUrl == null) throw "baseUrl 为空";

    try {
      var headers = _defaultHeadersForbaseUrl[baseUrl]; // 配置header
      if (headers == null) {
        final callBack =
            NetClientHeaders.fetchHeadersForbaseUrlCallBacks[baseUrl];
        if (callBack != null) {
          headers = await callBack();
          if (headers != null) {
            headers = Map<String, dynamic>.from(headers);
            _defaultHeadersForbaseUrl[baseUrl] = headers;
          }
        }
      }

      var cookie; // 配置cookie
      if (headers == null || headers[_kTextCookie] == null) {
        final callBack =
            NetClientHeaders.fetchCookiesForbaseUrlCallBacks[baseUrl];
        if (callBack != null) {
          cookie = await callBack();
          if (headers == null) {
            headers = Map<String, dynamic>.from({});
          }
          if (cookie != null) {
            headers[_kTextCookie] = cookie;
            _defaultHeadersForbaseUrl[baseUrl] = headers;
          }
        }
      }
    } catch (e) {
      debugPrint("_fetchHeadersFor error = $e");
    }
  }

  /// 传出set-cookie
  static _processCookieForResponse(Response response) {
    try {
      final baseUrl = response.request.baseUrl;
      final setCookies = response.headers.map["set-cookie"];
      if (setCookies != null) {
        final cookieStrings = setCookies.map((e) {
          final cookie = Cookie.fromSetCookieValue(e);
          final cookieString = cookie.name + "=" + cookie.value;
          return cookieString;
        }).toList();
        final totalCookie = cookieStrings.join(";");
        setCookie(totalCookie, baseUrl);
        _sendCookies(setCookies, baseUrl);
      }
    } catch (e) {
      debugPrint("_processCookieForResponse error = $e");
    }
  }

  /// 传出set-cookie
  static _sendCookies(List<String> setCookies, String baseUrl) async {
    try {
      if (NetClientHeaders.sendCookiesForbaseUrlCallBacks != null) {
        final callBack =
            NetClientHeaders.sendCookiesForbaseUrlCallBacks[baseUrl];
        if (callBack != null) {
          final jsonString = jsonEncode(setCookies);
          await callBack(jsonString);
        }
      }
    } catch (e) {
      debugPrint("_sendCookies error = $e");
    }
  }

  /*
   * 业务处理
   */
  static DYResponse _process(Response response) {
    debugPrint(
        '\n\n---------------------------------------NetClient---------------------------------------\n');
    debugPrint(
        'HttpSuccess >>>>>>>>>>【path       】: ${response.request.path} <<<<<<<<<<');
    debugPrint(
        'HttpSuccess >>>>>>>>>>【baseUrl    】: ${response.request.baseUrl} <<<<<<<<<<');
    debugPrint(
        'HttpSuccess >>>>>>>>>>【statusCode 】: ${response.statusCode} <<<<<<<<<<');
    debugPrint(
        'HttpSuccess >>>>>>>>>>【query      】: ${response.request.queryParameters} <<<<<<<<<<');
    debugPrint(
        'HttpSuccess >>>>>>>>>>【requestData】: ${(response.request.data is FormData) ? (response.request.data as FormData).fields : response.request.data} <<<<<<<<<<');
    debugPrint(
        'HttpSuccess >>>>>>>>>>【originData 】:  ${response.data} <<<<<<<<<<');
    debugPrint(
        'HttpSuccess >>>>>>>>>>【reqHeaders 】: ${response.request.headers} <<<<<<<<<<');
    debugPrint(
        'HttpSuccess >>>>>>>>>>【respHeaders】: ${response.headers} <<<<<<<<<<');
    debugPrint(
        'HttpSuccess >>>>>>>>>>【method     】: ${response.request.method} <<<<<<<<<<');

    debugPrint(
        '\n---------------------------------------NetClient---------------------------------------\n\n');

    final resonseObject = response.data;
    DYResponse dyResponse = DYResponse();

    dyResponse
      ..code = _transfer(response.statusCode) //http状态码，若有业务状态码，会被业务状态码覆盖
      ..message = response.statusMessage //http状态消息，若有业务状态消息，会被业务状态消息覆盖
      ..headers = response.headers.map //响应头
      ..originData = resonseObject; //后端返回的原始数据
    if (resonseObject is Map) {
      final errorCode = resonseObject["errorCode"] ?? resonseObject["code"];
      final errorMsg = resonseObject["errorMsg"] ?? resonseObject["msg"];
      final data = resonseObject["data"];
      final time = resonseObject["time"];

      final dyResponseCode = _transfer(errorCode);

      dyResponse.isSuccess = dyResponseCode == DYResponseCode.success;

      dyResponse
        ..code = dyResponseCode
        ..message = errorMsg
        ..data = data // 内部业务数据
        ..time = time; //服务器时间
    } else {
      dyResponse.data = resonseObject;
    }
    return dyResponse;
  }

  /*
   * error处理
   */
  static DYResponse _formatError(DioError error, String baseUrl, String path,
      {dynamic data}) {
    debugPrint(
        '\n\n---------------------------------------NetClient---------------------------------------\n');
    debugPrint('HttpFailure >>>>>>>>>>【error      】: $error <<<<<<<<<<');
    debugPrint('HttpFailure >>>>>>>>>>【path       】: $path <<<<<<<<<<');
    debugPrint('HttpFailure >>>>>>>>>>【baseUrl    】: $baseUrl <<<<<<<<<<');
    debugPrint('HttpFailure >>>>>>>>>>【requestData】: $data <<<<<<<<<<');
    debugPrint(
        '\n---------------------------------------NetClient---------------------------------------\n\n');

    final dyResponse = DYResponse();
    dyResponse.isSuccess = false;
    if (error.type == DioErrorType.CONNECT_TIMEOUT) {
      debugPrint("连接超时");
    } else if (error.type == DioErrorType.SEND_TIMEOUT) {
      debugPrint("请求超时");
      dyResponse.code = _transfer(408);
    } else if (error.type == DioErrorType.RECEIVE_TIMEOUT) {
      debugPrint("响应超时");
      dyResponse.code = _transfer(504);
    } else if (error.type == DioErrorType.RESPONSE) {
      // When the server response, but with a incorrect status, such as 404, 503...
      debugPrint("出现异常");
    } else if (error.type == DioErrorType.CANCEL) {
      debugPrint("请求取消");
      dyResponse.code = DYResponseCode.failure_cancelled;
    } else {
      debugPrint("未知错误");
    }
    return dyResponse;
  }

  /*
   * code转换为业务code
   */
  static DYResponseCode _transfer(responseCode) {
    if (responseCode == null) return DYResponseCode.other;

    if (responseCode == 0 || responseCode == 200) {
      return DYResponseCode.success;
    }

    if (responseCode == 401) {
      return DYResponseCode.failure_unauthorized;
    }

    if (responseCode >= 400 && responseCode < 500) {
      return DYResponseCode.failure_client;
    }

    if (responseCode >= 500 && responseCode < 600) {
      return DYResponseCode.failure_server;
    }

    return DYResponseCode.other;
  }
}

const _kTextCookie = "cookie";
