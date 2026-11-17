import 'package:material_ui/material_ui.dart';

import 'data/api_client.dart';

void main() {
  runApp(const NeteasyApp());
}

/// 阶段 0 的验证壳：只证明「本地 Rust 后端已就绪 + 接口能通」。
/// 真正的首页在阶段 1 之后替换这里。
class NeteasyApp extends StatelessWidget {
  const NeteasyApp({super.key});

  /// 网易云品牌红，来源 Kotlin 版 ui/theme/Color.kt 的 LightPrimary
  static const Color brandRed = Color(0xFFD92D1F);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'neteasy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: brandRed),
        brightness: .light,
      ),
      darkTheme: ThemeData(
        colorScheme: .fromSeed(seedColor: brandRed, brightness: .dark),
        brightness: .dark,
      ),
      home: const BackendProbePage(),
    );
  }
}

class BackendProbePage extends StatefulWidget {
  const BackendProbePage({super.key});

  @override
  State<BackendProbePage> createState() => _BackendProbePageState();
}

class _BackendProbePageState extends State<BackendProbePage> {
  final ApiClient _api = ApiClient();
  final List<_ProbeLine> _lines = [];
  String _headline = '等待本地后端…';
  bool _ok = false;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _probe();
  }

  Future<void> _probe() async {
    setState(() {
      _running = true;
      _ok = false;
      _headline = '等待本地后端…';
      _lines.clear();
    });

    final total = Stopwatch()..start();
    try {
      await _run('/login/status', () async {
        final json = await _api.get('/login/status');
        final account = json['account'];
        if (account is Map && account['id'] != null) {
          return '已登录 uid=${account['id']}';
        }
        return '游客态（未登录）';
      });

      await _run('/banner', () async {
        final json = await _api.get('/banner', {'type': '2'});
        final banners = json['banners'];
        if (banners is! List) return '无 banners 字段';
        final titles = banners
            .whereType<Map>()
            .map((b) => b['typeTitle'] ?? b['title'] ?? '(无标题)')
            .take(3)
            .join(' / ');
        return '${banners.length} 条：$titles';
      });

      await _run('/personalized', () async {
        final json = await _api.get('/personalized', {'limit': '6'});
        final result = json['result'];
        if (result is! List) return '无 result 字段';
        final names = result
            .whereType<Map>()
            .map((p) => p['name'] ?? '(无名称)')
            .take(3)
            .join(' / ');
        return '${result.length} 个歌单：$names';
      });

      setState(() {
        _ok = true;
        _headline = '后端就绪，全部通过（${total.elapsedMilliseconds} ms）';
      });
    } on ApiException catch (e) {
      setState(() => _headline = '失败：$e');
    } catch (e) {
      setState(() => _headline = '异常：$e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _run(String label, Future<String> Function() body) async {
    final sw = Stopwatch()..start();
    final detail = await body();
    if (!mounted) return;
    setState(() {
      _lines.add(_ProbeLine(label, detail, sw.elapsedMilliseconds));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('后端联通自检'),
        backgroundColor: scheme.surfaceContainer,
        actions: [
          IconButton(
            onPressed: _running ? null : _probe,
            icon: const Icon(Icons.refresh),
            tooltip: '重新检测',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: _ok ? scheme.primaryContainer : scheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_running)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(_ok ? Icons.check_circle : Icons.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_headline)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final line in _lines)
            ListTile(
              dense: true,
              horizontalTitleGap: 8,
              leading: Text(
                '${line.elapsedMs}ms',
                style: theme.textTheme.labelSmall,
              ),
              title: Text(line.label),
              subtitle: Text(line.detail),
            ),
          const SizedBox(height: 24),
          Text(
            '127.0.0.1:19800 · cookie: ${_api.cookies.isEmpty ? '空' : _api.cookies.keys.join(',')}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ProbeLine {
  _ProbeLine(this.label, this.detail, this.elapsedMs);

  final String label;
  final String detail;
  final int elapsedMs;
}
