/// 扫码登录状态。
///
/// 状态码语义与官方扫码登录一致，**别写反**：
/// `801` 等待扫码、`800` 已过期、`802` 已扫码待确认、`803` 登录成功。
enum QrLoginState {
  /// 还没开始
  idle,

  /// 正在取 key / 生成二维码
  loading,

  /// 801：等待扫码（正常轮询态）
  waiting,

  /// 802：已扫码，等手机确认
  scanned,

  /// 800：二维码过期
  expired,

  /// 803：登录成功
  success,

  /// 网络异常或接口失败
  failed,
}

extension QrLoginStateHint on QrLoginState {
  /// 二维码下方给用户看的提示
  String get hint => switch (this) {
    QrLoginState.idle => '点击下方按钮生成二维码',
    QrLoginState.loading => '正在生成二维码…',
    QrLoginState.waiting => '请使用网易云音乐 App 扫码登录',
    QrLoginState.scanned => '已扫码，请在手机上确认',
    QrLoginState.expired => '二维码已过期，点击刷新',
    QrLoginState.success => '登录成功',
    QrLoginState.failed => '获取二维码失败，请稍后重试',
  };

  /// 是否还需要继续轮询
  bool get polling =>
      this == QrLoginState.waiting || this == QrLoginState.scanned;

  /// 二维码是否可点刷新
  bool get needRefresh =>
      this == QrLoginState.expired ||
      this == QrLoginState.failed ||
      this == QrLoginState.idle;
}
