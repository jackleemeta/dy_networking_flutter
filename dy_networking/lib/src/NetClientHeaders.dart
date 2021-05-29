typedef HeadersCookieForbaseUrlCallBack = Future<dynamic> Function();

typedef SendSetCookieForbaseUrlCallBack = Future<dynamic> Function(
    String cookie);

class NetClientHeaders {
  static Map<String, HeadersCookieForbaseUrlCallBack>
      fetchHeadersForbaseUrlCallBacks = {};
  static Map<String, HeadersCookieForbaseUrlCallBack>
      fetchCookiesForbaseUrlCallBacks = {};
  static Map<String, SendSetCookieForbaseUrlCallBack>
      sendCookiesForbaseUrlCallBacks = {};
}
