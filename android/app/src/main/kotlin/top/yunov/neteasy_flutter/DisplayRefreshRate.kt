package top.yunov.neteasy_flutter

import android.app.Activity
import android.os.Build
import android.util.Log
import android.view.Display
import android.view.WindowManager

/**
 * 向系统申请显示器的最高刷新率。
 *
 * Flutter 引擎从不向系统声明帧率——3.50 的 embedding 里 setFrameRate /
 * preferredRefreshRate / preferredDisplayModeId 一个都没有，系统只能按自己的
 * 默认策略选显示模式。按包名记高刷档位的 ROM（小米等）会因此把整包钉在 60Hz；
 * 而 debug 与 release 共用同一个 applicationId，debug 留下的"只跑 60"的记录
 * 会带到 release 包上。这里在窗口属性里显式声明一次，把"要最高档"塞进系统的
 * 选模式输入。
 *
 * 只在同分辨率的模式里挑最高刷新率：换分辨率会让 Flutter 重建绘图缓冲，
 * 而且大分辨率模式通常还更耗电。
 */
internal object DisplayRefreshRate {
    private const val TAG = "DisplayRefreshRate"

    /** 基准档。60Hz 面板实测报 60.000004，留 1Hz 余量判断"有没有更高的档"。 */
    private const val BASE_RATE = 60f
    private const val RATE_EPSILON = 1f

    fun requestMax(activity: Activity) {
        runCatching { apply(activity) }
            .onFailure { Log.w(TAG, "申请最高刷新率失败", it) }
    }

    private fun apply(activity: Activity) {
        val display: Display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            activity.display ?: return
        } else {
            @Suppress("DEPRECATION")
            activity.windowManager.defaultDisplay
        }

        val current: Display.Mode = display.mode
        val best: Display.Mode = display.supportedModes
            .filter { mode ->
                mode.physicalWidth == current.physicalWidth &&
                    mode.physicalHeight == current.physicalHeight
            }
            .maxByOrNull { it.refreshRate } ?: return
        if (best.refreshRate - BASE_RATE < RATE_EPSILON) return

        val params: WindowManager.LayoutParams = activity.window.attributes
        // 属性值没变就别反复写，写一次会触发一趟窗口重排
        if (params.preferredDisplayModeId == best.modeId) return

        // 两个都写：preferredDisplayModeId 生效时 preferredRefreshRate 被忽略，
        // 但有的 ROM 只认后者，留着兜底。
        params.preferredRefreshRate = best.refreshRate
        params.preferredDisplayModeId = best.modeId
        activity.window.attributes = params
        Log.i(TAG, "申请 ${best.refreshRate}Hz（modeId=${best.modeId}）")
    }
}
