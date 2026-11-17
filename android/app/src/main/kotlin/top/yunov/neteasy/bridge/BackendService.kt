package top.yunov.neteasy.bridge

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import java.io.File
import top.yunov.neteasy.RustBackend

/**
 * 前台服务：运行内嵌的 Rust 后端（neteasy-backend）。
 *
 * - 直接调用 JNI 的 [RustBackend.start]，端口 127.0.0.1:19800 绑定成功后才返回
 * - 设备 ID / xeapi 公钥 / 游客 token 缓存在 filesDir/neteasy-backend，热启动即刻可用
 *
 * 来源：`D:/Documents/AndroidProjects/neteasy`（Kotlin 版）的
 * `top/yunov/neteasy/bridge/BackendService.kt`。改动：去掉旧版 Node 后端的残留清理逻辑，
 * 新增 [start] 供 Application 调用，通知图标改用 applicationInfo.icon（新工程的 R 在另一个包）。
 */
class BackendService : Service() {
    companion object {
        private const val TAG = "BackendService"
        private const val CHANNEL_ID = "backend_service"
        private const val NOTIF_ID = 19800

        /** 后端监听的端口，Dart 侧 ApiClient 的 baseUrl 必须与它一致 */
        const val PORT = 19800

        /** 后端的数据目录名；存设备 ID 等运行必需的状态，清理缓存时要跳过 */
        const val DATA_DIR_NAME = "neteasy-backend"

        /** 拉起后端服务。Android 8+ 必须走 startForegroundService。 */
        fun start(context: Context) {
            val intent = Intent(context, BackendService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "BackendService onCreate")
        startAsForeground()
        Thread {
            try {
                val dataDir = File(filesDir, DATA_DIR_NAME).apply { mkdirs() }
                if (RustBackend.isRunning()) {
                    // 服务被系统重建/重复拉起时，后端线程其实一直在跑，不需要再启动
                    Log.i(TAG, "后端已在运行，跳过启动")
                    return@Thread
                }
                val startedAt = System.nanoTime()
                val started = RustBackend.start(dataDir.absolutePath, PORT)
                val cost = (System.nanoTime() - startedAt) / 1_000_000
                if (started) {
                    Log.i(TAG, "后端已启动（端口已绑定，耗时 ${cost}ms）")
                } else {
                    // 多半是端口被别的进程占用；Dart 侧会连接失败并把错误展示出来
                    Log.e(TAG, "后端启动失败（端口 $PORT 可能被占用）")
                }
            } catch (t: Throwable) {
                Log.e(TAG, "启动 Rust 后端失败", t)
            }
        }.start()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    override fun onDestroy() {
        Log.i(TAG, "BackendService onDestroy（后端线程不受服务生命周期管理，进程存活时仍会运行）")
        super.onDestroy()
    }

    private fun startAsForeground() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_ID, "neteasy 后端服务", NotificationManager.IMPORTANCE_LOW).apply {
                description = "运行本地后端（localhost:$PORT）"
            }
        )
        val notification: Notification =
            NotificationCompat
                .Builder(this, CHANNEL_ID)
                .setContentTitle("neteasy 后端服务")
                .setContentText("后端运行中（http://127.0.0.1:$PORT）")
                .setSmallIcon(applicationInfo.icon)
                .setOngoing(true)
                .build()
        try {
            ServiceCompat.startForeground(
                this,
                NOTIF_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } catch (e: RuntimeException) {
            // Android 12+ 或国产 ROM 可能限制后台启动前台服务。
            // 降级处理：后端照常启动，仅无前台通知。
            Log.w(TAG, "startForeground 失败（降级：后端仍将启动）", e)
        }
    }
}
