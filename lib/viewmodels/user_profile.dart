/// 登录用户。
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.nickname,
    this.avatarUrl = '',
    this.vipType = 0,
  });

  final int uid;
  final String nickname;
  final String avatarUrl;

  /// 0 = 非会员，>0 = 黑胶/VIP 等档位
  final int vipType;

  bool get isVip => vipType > 0;

  /// 昵称为空时用 uid 兜底，避免「我的」页出现空白标题
  String get displayName => nickname.isEmpty ? '用户 $uid' : nickname;
}
