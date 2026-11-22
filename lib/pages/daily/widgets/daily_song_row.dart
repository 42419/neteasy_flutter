import 'package:material_ui/material_ui.dart';

import '../../../components/cover_thumb.dart';
import '../../../components/vip_badge.dart';
import '../../../constants/app_constants.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/song.dart';

/// 列表行：40 封面 + 歌名 + 推荐语/歌手专辑 + MV 徽章（有才画）+ 更多。
///
/// 官方行里没有播放键——右边第一个图标就是 MV，容易认错。
/// 正在播放的那首把歌名染成品牌红，除此之外行样式不变。
class DailySongRow extends StatelessWidget {
  const DailySongRow({
    super.key,
    required this.song,
    required this.playing,
    required this.onTap,
  });

  final Song song;

  /// 正在播放这一首：歌名染成品牌红
  final bool playing;

  final VoidCallback onTap;

  /// 行高，官方量出来就是 60
  static const double rowHeight = 60;

  /// 封面边长
  static const double _coverSize = 40;

  String get _meta {
    if (song.albumName.isEmpty) {
      return song.artist;
    }
    return '${song.artist} - ${song.albumName}';
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppTheme.colorsOf(context);
    final DailyColors daily = AppTheme.dailyOf(context);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: rowHeight,
        child: Padding(
          padding: const EdgeInsets.only(left: AppTheme.pagePadding, right: 16),
          child: Row(
            children: <Widget>[
              CoverThumb(url: song.coverUrl, size: _coverSize),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      song.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.25,
                        color: playing ? AppTheme.brand : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        if (song.isVip) ...<Widget>[
                          const VipBadge(height: VipBadge.rowHeight),
                          const SizedBox(width: 4),
                        ],
                        if (song.reason.isNotEmpty) ...<Widget>[
                          _ReasonBadge(text: song.reason, daily: daily),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            _meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.caption(colors)
                                .copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (song.mvId > 0) ...<Widget>[
                // 有 MV 才画徽章：实测 19×17dp，右边距 16 接 ⋮
                Image.asset(
                  AppConstants.mvIcon,
                  height: 17,
                  color: colors.textSecondary,
                  colorBlendMode: BlendMode.srcIn,
                ),
                const SizedBox(width: 16),
              ],
              SizedBox(
                width: 24,
                height: 40,
                child: Center(
                  child: Image.asset(
                    AppConstants.moreIcon,
                    width: 4,
                    height: 20,
                    color: colors.textSecondary,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 推荐语：粉底红字（深色下换暗红底，粉底在黑夜模式里太刺眼）
class _ReasonBadge extends StatelessWidget {
  const _ReasonBadge({required this.text, required this.daily});

  final String text;
  final DailyColors daily;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: daily.reasonChipBackground,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          height: 1.2,
          color: daily.reasonChipColor,
        ),
      ),
    );
  }
}
