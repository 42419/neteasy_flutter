package top.yunov.neteasy_flutter

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 首帧之前声明，避免先以 60Hz 起一屏再切到高刷
        DisplayRefreshRate.requestMax(this)
    }

    override fun onResume() {
        super.onResume()
        // 回到前台时系统会重新按策略选显示模式，这里再声明一次
        DisplayRefreshRate.requestMax(this)
    }
}
