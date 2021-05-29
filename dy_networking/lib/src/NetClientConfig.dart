import 'NetClientHeaders.dart';
import 'NetClient.dart';

class NetClientConfig {
  /// 代理模式
  static bool isProxyMode = false;

  /// 本地代理
  static String localProxyHost;

  /// 注册设置header句柄
  static void registerFetchingHeadersForbaseUrlHandler(
      String baseUrl, HeadersCookieForbaseUrlCallBack callBack) {
    if (callBack == null) return;
    NetClientHeaders.fetchHeadersForbaseUrlCallBacks
        .addAll({baseUrl: callBack});
  }

  /// 注册设置cookie句柄
  static void registerFetchingCookieForbaseUrlHandler(
      String baseUrl, HeadersCookieForbaseUrlCallBack callBack) {
    if (callBack == null) return;
    NetClientHeaders.fetchCookiesForbaseUrlCallBacks
        .addAll({baseUrl: callBack});
  }

  /// 注册传出cookie句柄
  static void registerSendSetCookieForbaseUrlHandler(
      String baseUrl, SendSetCookieForbaseUrlCallBack callBack) {
    if (callBack == null) return;
    NetClientHeaders.sendCookiesForbaseUrlCallBacks.addAll({baseUrl: callBack});
  }

  /// 设置headers
  ///
  /// [headers]
  /// [forBaseUrl] url
  static void setHeaders(Map headers, String forBaseUrl) {
    NetClient.setHeaders(headers, forBaseUrl);
  }

  /// 清理指定headers
  ///
  /// [baseUrl] headers所绑定的url
  static clearHeaderForBaseUrl(String baseUrl) async {
    await NetClient.clearHeaderForBaseUrl(baseUrl);
  }

  /// 清理所有header
  static clearAllHeader() async {
    await NetClient.clearAllHeader();
  }

  /// 设置cookie
  ///
  /// [cookie] cookie
  /// [forBaseUrl] url
  static void setCookie(String cookie, String forBaseUrl) {
    NetClient.setCookie(cookie, forBaseUrl);
  }

  /// 清理指定cookie
  ///
  /// [baseUrl] cookie所绑定的url
  static clearCookieForBaseUrl(String baseUrl) async {
    await NetClient.clearCookieForBaseUrl(baseUrl);
  }

  /// 清理所有cookie
  static clearAllCookie() async {
    await NetClient.clearAllCookie();
  }
}
