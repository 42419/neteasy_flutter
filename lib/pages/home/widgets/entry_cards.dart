import 'package:material_ui/material_ui.dart';

import '../../../theme/app_theme.dart';
import '../../../viewmodels/home_entry.dart';
import 'cover_image.dart';

/// 首页顶部入口卡一排。
///
/// [entries] 为空时用内置的 6 张（写死文案 + 渐变），
/// 有数据（dragon ball 下发）时用真实标题与运营图，配色按序轮换兜底。
class EntryCards extends StatelessWidget {
  const EntryCards({
    super.key,
    this.entries = const <HomeEntry>[],
    this.onTap,
    this.leadImageUrl = '',
  });

  final List<HomeEntry> entries;

  /// 点了第几张；没接目标页时传 null
  final void Function(int index)? onTap;

  /// 首张卡（每日推荐）的底图：登录后取今天第一首推荐歌的封面
  final String leadImageUrl;

  /// 内置兜底：官方这 6 个入口的固定文案与配色
  static const List<_DefaultEntry> _defaults = <_DefaultEntry>[
    _DefaultEntry('每日推荐', '今日限定好歌推荐', <Color>[
      Color(0xFF4A4A52),
      Color(0xFF23232A),
    ]),
    _DefaultEntry('榜单推荐', '云音乐官方 top 排...', <Color>[
      Color(0xFFFF6B6B),
      Color(0xFFD63B3B),
    ]),
    _DefaultEntry('心动模式', '红心歌曲和相似歌单', <Color>[
      Color(0xFF3E5AA8),
      Color(0xFF23335F),
    ]),
    _DefaultEntry('雷达歌单', '反复聆听你爱的歌', <Color>[
      Color(0xFF2E1559),
      Color(0xFF050C20),
    ]),
    _DefaultEntry('漫游', '多样频道无限畅听', <Color>[
      Color(0xFF91A83E),
      Color(0xFF5F5523),
    ]),
    _DefaultEntry('相似歌曲', '从你喜欢的歌听起', <Color>[
      Color(0xFF3EA888),
      Color(0xFF235F31),
    ]),
  ];

  /// 真实数据不带配色，按下标轮换一套，图没加载出来时不至于露白底
  static const List<List<Color>> _palettes = <List<Color>>[
    <Color>[Color(0xFF4A4A52), Color(0xFF23232A)],
    <Color>[Color(0xFFFF6B6B), Color(0xFFD63B3B)],
    <Color>[Color(0xFF3E5AA8), Color(0xFF23335F)],
    <Color>[Color(0xFF2E1559), Color(0xFF050C20)],
    <Color>[Color(0xFF91A83E), Color(0xFF5F5523)],
    <Color>[Color(0xFF3EA888), Color(0xFF235F31)],
  ];

  @override
  Widget build(BuildContext context) {
    final bool useDefaults = entries.isEmpty;
    final int count = useDefaults ? _defaults.length : entries.length;
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.pagePadding,
          8,
          AppTheme.pagePadding,
          0,
        ),
        itemCount: count,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final Widget card;
          if (useDefaults) {
            final _DefaultEntry entry = _defaults[index];
            card = EntryCard(
              title: entry.title,
              subtitle: entry.subtitle,
              colors: entry.colors,
              imageUrl: index == 0 ? leadImageUrl : '',
            );
          } else {
            final HomeEntry entry = entries[index];
            card = EntryCard(
              title: entry.title,
              subtitle: entry.subtitle,
              colors: _palettes[index % _palettes.length],
              imageUrl: entry.imageUrl.isNotEmpty
                  ? entry.imageUrl
                  : (index == 0 ? leadImageUrl : ''),
            );
          }
          final void Function(int index)? tap = onTap;
          if (tap == null) {
            return card;
          }
          return GestureDetector(onTap: () => tap(index), child: card);
        },
      ),
    );
  }
}

/// 单张入口卡：有运营图就铺图，没有就用渐变
class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.colors,
    this.imageUrl = '',
  });

  final String title;
  final String subtitle;
  final List<Color> colors;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final AppColors paletteColors = AppTheme.colorsOf(context);
    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        color: imageUrl.isEmpty ? null : paletteColors.placeholder,
        gradient: imageUrl.isEmpty
            ? LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          if (imageUrl.isNotEmpty)
            Positioned.fill(
              child: CoverImage(url: imageUrl, logicalWidth: 150),
            ),
          // 底部压暗，保证文字可读
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                  stops: const <double>[0.45, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            right: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            right: 8,
            bottom: 12,
            child: Icon(
              Icons.play_arrow_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// 内置入口的文案与配色
class _DefaultEntry {
  const _DefaultEntry(this.title, this.subtitle, this.colors);

  final String title;
  final String subtitle;
  final List<Color> colors;
}
