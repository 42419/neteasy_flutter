import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/format.dart';
import '../../../viewmodels/rank.dart';
import 'section_parts.dart';

/// 排行榜卡片：渐变底 + 榜名居中大字 + 右上播放量 + 右下播放键，
/// 卡片下方接前 3 首歌名（顿号连接，两行截断）。
class RankCard extends StatelessWidget {
  const RankCard({super.key, required this.rank, required this.index});

  final Rank rank;
  final int index;

  /// 按顺序循环。官方是绿/橙/蓝/紫几套。
  static const List<List<Color>> palettes = <List<Color>>[
    <Color>[Color(0xFF7BD3A8), Color(0xFF3BAF7A)],
    <Color>[Color(0xFFFFC46B), Color(0xFFF08C2E)],
    <Color>[Color(0xFF9EC5FF), Color(0xFF5B8DEF)],
    <Color>[Color(0xFFD3A8FF), Color(0xFF9A5BEF)],
  ];

  @override
  Widget build(BuildContext context) {
    final List<Color> palette = palettes[index % palettes.length];
    final AppColors colors = AppTheme.colorsOf(context);
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              gradient: LinearGradient(
                colors: palette,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: <Widget>[
                // 榜名居中大字
                Center(
                  child: Text(
                    rank.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                // 右上角播放量
                if (rank.playCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.headphones,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 1),
                        Text(
                          formatCount(rank.playCount),
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.1,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Positioned(
                  right: 3,
                  bottom: 3,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 33,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            rank.trackLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.cardTitle(colors),
          ),
        ],
      ),
    );
  }
}

/// 排行榜区块
class RankSection extends StatelessWidget {
  const RankSection({super.key, required this.ranks});

  final List<Rank> ranks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionHeader(title: '排行榜', showMore: true),
        HorizontalList(
          height: 200,
          itemCount: ranks.length,
          itemBuilder: (BuildContext context, int index) =>
              RankCard(rank: ranks[index], index: index),
        ),
      ],
    );
  }
}
