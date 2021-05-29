/*
 *
 * 业务用返回对象相关
 * 
 */

///Code
enum DYResponseCode {
  success, //成功
  failure_unauthorized, //失败 - 授权凭证失效
  failure_request_timeout, //失败 - 请求超时
  failure_response_timeout, //失败 - 响应超时
  failure_client, //失败 - 客户端原因
  failure_server, //失败 - 服务端原因
  failure_cancelled, //失败 - 取消请求
  other
}

///DYResponse
class DYResponse {
  bool isSuccess; //是否请求成功，已处理http请求结果和业务请求结果
  Map headers; //响应头
  dynamic data; //业务data，已去除errorCode等外层字段
  DYResponseCode code; //状态码
  String message; //状态消息
  Map originData; //原始data
  int time; //服务器时间
}
