/// 网络延迟探测（平台无关接口）
///
/// Web 平台使用 HTTP 请求探测
/// 非 Web 平台使用 Socket 连接探测
Future<int> probeNetworkLatency() => throw UnsupportedError('No implementation');
