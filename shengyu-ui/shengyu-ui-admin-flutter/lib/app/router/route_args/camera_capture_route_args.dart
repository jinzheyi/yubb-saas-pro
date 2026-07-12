/// 自定义相机页面路由参数。
class CameraCaptureRouteArgs {
  const CameraCaptureRouteArgs({this.initialMode = CameraCaptureMode.photo});

  /// 初始模式（拍照/录像）。
  final CameraCaptureMode initialMode;
}

/// 相机拍摄模式。
enum CameraCaptureMode {
  /// 拍照模式。
  photo,

  /// 录像模式。
  video,
}
