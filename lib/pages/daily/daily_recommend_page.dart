import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../components/empty_hint.dart';
import '../../components/error_retry.dart';
import '../../components/mini_player/mini_player.dart';
import '../../stores/daily_store.dart';
import '../../stores/player_store.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/song.dart';
import 'widgets/daily_header.dart';
import 'widgets/daily_hint_row.dart';
import 'widgets/daily_skeleton.dart';
import 'widgets/daily_song_row.dart';

/// 每日推荐页：首页「每日推荐」卡进入，数据来自 `/recommend/songs`。
///
/// store 挂在全局：首页加载时已经用同一份响应预热过，所以正常进页面
/// **首帧就有歌**，不再等一次请求。只有首次进入、跨天失效、换账号时
/// 才在这里补一次，等待期画骨架。
///
/// 只做编排：渐变头 + 提示行 + 歌曲列表。头部各块在 `widgets/` 下。
class DailyRecommendPage extends StatefulWidget {
  const DailyRecommendPage({super.key});

  @override
  State<DailyRecommendPage> createState() => _DailyRecommendPageState();
}

class _DailyRecommendPageState extends State<DailyRecommendPage> {
  @override
  void initState() {
    super.initState();
    // 首帧之后再补：首页的 prime 可能刚跑完，没必要多打一次
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DailyStore>().ensureLoaded();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final DailyStore store = context.watch<DailyStore>();
    // songs 已按「推荐日」过滤：跨天后这里为空，页面画骨架等新的
    final List<Song> songs = store.songs;
    final bool failed = store.error != null && songs.isEmpty;
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
          else if (store.waiting)
            // 首次进入 / 跨天：骨架顶住，行高与真实列表一致，数据到了不跳
            const SliverToBoxAdapter(child: DailySkeleton())
          else if (songs.isEmpty)
            // 问过接口但就是没有（未登录最常见）：别让骨架一直转
            const SliverToBoxAdapter(
              child: EmptyHint(
                text: '暂无推荐',
                padding: EdgeInsets.symmetric(vertical: 80),
              ),
            )
          else ...<Widget>[
            const SliverToBoxAdapter(child: DailyHintRow()),
            SliverList.builder(
              itemCount: songs.length,
              itemBuilder: (BuildContext context, int index) => DailySongRow(
                song: songs[index],
                playing: songs[index].id == playingId,
                onTap: () =>
                    context.read<PlayerStore>().playQueue(songs, index: index),
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
