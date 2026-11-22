import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../components/error_retry.dart';
import '../../components/mini_player/mini_player.dart';
import '../../stores/daily_store.dart';
import '../../stores/player_store.dart';
import '../../theme/app_theme.dart';
import 'widgets/daily_header.dart';
import 'widgets/daily_hint_row.dart';
import 'widgets/daily_song_row.dart';

/// 每日推荐页：首页「每日推荐」卡进入，数据来自 `/recommend/songs`。
///
/// 只做编排：渐变头 + 提示行 + 歌曲列表。头部各块在 `widgets/` 下。
class DailyRecommendPage extends StatelessWidget {
  const DailyRecommendPage({super.key});

  @override
  Widget build(BuildContext context) {
    final DailyStore store = context.watch<DailyStore>();
    final bool failed = store.error != null && store.songs.isEmpty;
    // 只订阅「当前歌曲 id」：进度、缓冲这类高频变化不会重建整页
    final int? playingId = context.select<PlayerStore, int?>(
      (PlayerStore player) => player.currentSongId,
    );

    return Scaffold(
      backgroundColor: AppTheme.colorsOf(context).background,
      // 列表要能滑到迷你播放器下面，底部渐隐才有东西可以淡出
      extendBody: true,
      // 没有底栏的子页面：迷你播放器自己避开手势条
      bottomNavigationBar: const MiniPlayerBar(safeBottom: true),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: DailyHeader(store: store)),
          if (failed)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorRetry(message: store.error!, onRetry: store.load),
            )
          else ...<Widget>[
            const SliverToBoxAdapter(child: DailyHintRow()),
            SliverList.builder(
              itemCount: store.songs.length,
              itemBuilder: (BuildContext context, int index) => DailySongRow(
                song: store.songs[index],
                playing: store.songs[index].id == playingId,
                onTap: () => context.read<PlayerStore>().playQueue(
                  store.songs,
                  index: index,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom + 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
