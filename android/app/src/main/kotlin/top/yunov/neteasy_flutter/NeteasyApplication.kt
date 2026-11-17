package top.yunov.neteasy_flutter

import android.app.Application
import android.util.Log
import top.yunov.neteasy.bridge.BackendService

/**
 * 进程启动时拉起本地 Rust 后端（neteasy-backend）。
 *
 * Flutter 侧不感知 Kotlin 的存在，只请求 http://127.0.0.1:19800。
 * 冷启动就绪由 Dart 侧的 ApiClient 轮询等待（只对"连不上"重试）。
 */
class NeteasyApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        runCatching { BackendService.start(this) }
            .onFailure { Log.e("NeteasyApplication", "拉起后端服务失败", it) }
    }
}
