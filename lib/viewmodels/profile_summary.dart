import 'playlist.dart';
import 'user_profile.dart';

/// 「我的」页一屏所需的数据：身份信息 + 会员 / 徽章 / 听歌时长 / 歌单数 + 歌单列表。
///
/// 由 `ProfileStore` 把几个接口拼起来，页面只读这个对象。
class ProfileSummary {
  const ProfileSummary({
    required this.user,
    this.vipLevel = 0,
    this.svipActive = false,
    this.badgeCount = 0,
    this.listenHours = 0,
    this.createdPlaylists = 0,
    this.collectedPlaylists = 0,
    this.playlists = const <Playlist>[],
  });

  final UserProfile user;

  /// 黑胶等级 1–10，0 表示没有会员
  final int vipLevel;

  /// 黑胶 SVIP 是否在有效期内
  final bool svipActive;

  /// 能佩戴的徽章数（不是接口里的 medalNum）
  final int badgeCount;

  /// 累计听歌小时数
  final int listenHours;

  final int createdPlaylists;
  final int collectedPlaylists;

  /// 「近期」标签下的歌单：我喜欢的音乐固定第一，其余按更新时间倒序
  final List<Playlist> playlists;

  static const List<String> _numerals = <String>[
    '',
    '壹',
    '贰',
    '叁',
    '肆',
    '伍',
    '陆',
    '柒',
    '捌',
    '玖',
    '拾',
  ];

  /// 昵称旁的会员徽章文案，没会员时为空串
  String get vipLabel {
    if (vipLevel <= 0) {
      return '';
    }
    final int index = vipLevel.clamp(0, _numerals.length - 1);
    return '${svipActive ? 'SVIP' : 'VIP'}·${_numerals[index]}';
  }

  bool get isEmpty => user.uid == 0;
}
