import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../stores/session_store.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/login_qr.dart';

/// 扫码登录页。
///
/// 进页面就拉一次 key 并生成二维码，之后每 2 秒轮询一次状态；
/// 登录成功后自动返回上一页。
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _popped = false;

  /// dispose 里不能再 context.read，提前拿住
  late SessionStore _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_session.loggedIn) {
        _popOnce();
      } else {
        _session.startQrLogin();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _session = context.read<SessionStore>();
  }

  @override
  void dispose() {
    // 离开页面时停掉轮询，避免后台一直打 /login/qr/check
    _session.cancelQrLogin();
    super.dispose();
  }

  void _popOnce() {
    if (_popped) {
      return;
    }
    _popped = true;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final SessionStore session = context.watch<SessionStore>();

    if (session.qrState == QrLoginState.success && session.loggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _popOnce();
        }
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('扫码登录'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildQrCard(session),
                    const SizedBox(height: 20),
                    Text(
                      session.qrState.hint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (session.qrError != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        session.qrError!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: scheme.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (session.qrState.needRefresh)
                      FilledButton.tonal(
                        onPressed: session.startQrLogin,
                        child: const Text('刷新二维码'),
                      ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                '二维码 5 分钟内有效\n请勿将二维码分享给他人',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppTheme.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCard(SessionStore session) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.placeholder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Padding(padding: const EdgeInsets.all(14), child: _buildQr(session)),
          if (session.qrState == QrLoginState.expired)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              alignment: Alignment.center,
              child: const Text(
                '二维码已过期',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQr(SessionStore session) {
    switch (session.qrState) {
      case QrLoginState.loading:
      case QrLoginState.idle:
        return const Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        );
      case QrLoginState.success:
        return const Center(
          child: Icon(Icons.check_circle, size: 64, color: AppTheme.brand),
        );
      default:
        final Uint8List? bytes = session.qrBytes;
        if (bytes == null) {
          return const Center(child: Text('加载失败', style: AppTheme.caption));
        }
        return Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true);
    }
  }
}
