import 'package:material_ui/material_ui.dart';

/// 迷你播放器底下那层渐隐。
///
/// 中线以上从透明渐到实色、中线以下实色铺到屏幕底边，
/// 列表滑到这儿就淡出去，不会硬邦邦地被胶囊切断。
///
/// 单独抽出来是因为这里有个坑：Column 默认 `center` 是横向松约束，
/// 没有子节点的 `DecoratedBox` / `ColoredBox` 宽度会塌成 0——
/// 遮罩整条不画，但页面看起来一切正常，很难发现。必须 `stretch`。
class MiniPlayerScrim extends StatelessWidget {
  const MiniPlayerScrim({
    super.key,
    required this.color,
    required this.fadeHeight,
  });

  /// 实色端（浅色=页面底色，深色比页面更暗）
  final Color color;

  /// 从透明到实色的高度，也就是胶囊中线的位置
  final double fadeHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: fadeHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[color.withValues(alpha: 0), color],
              ),
            ),
          ),
        ),
        Expanded(child: ColoredBox(color: color)),
      ],
    );
  }
}
