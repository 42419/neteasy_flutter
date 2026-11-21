/// 登录用户的基本身份信息。
///
/// 「我的」页还要展示关注数、等级、听歌时长等，那些由 [ProfileSummary] 聚合，
/// 这里只放登录态本身需要的字段。
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.nickname,
    this.avatarUrl = '',
    this.vipType = 0,
    this.gender = 0,
    this.signature = '',
    this.follows = 0,
    this.followeds = 0,
    this.level = 0,
    this.listenSongs = 0,
    this.recordPrivate = false,
  });

  final int uid;
  final String nickname;
  final String avatarUrl;

  /// 0 = 非会员，>0 = 黑胶/VIP 等档位
  final int vipType;

  /// 1 = 男，2 = 女，0 = 未设置
  final int gender;

  final String signature;

  final int follows;
  final int followeds;

  /// 账号等级（页面上是 Lv.N）
  final int level;

  /// 累计听过的歌曲数
  final int listenSongs;

  /// 听歌记录是否对他人隐藏（true 时「听歌排行」右侧挂锁）
  final bool recordPrivate;

  bool get isVip => vipType > 0;

  bool get isFemale => gender == 2;

  /// 昵称为空时用 uid 兜底，避免「我的」页出现空白标题
  String get displayName => nickname.isEmpty ? '用户 $uid' : nickname;
}
