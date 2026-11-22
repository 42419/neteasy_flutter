package top.yunov.neteasy_flutter

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.core.content.ContextCompat
import com.airbnb.lottie.LottieAnimationView
import com.airbnb.lottie.LottieProperty
import com.airbnb.lottie.model.KeyPath
import com.airbnb.lottie.value.LottieValueCallback
import com.ryanheise.audioservice.AudioServiceActivity

// audio_service 要求 Activity 与后台播放服务共用同一个 FlutterEngine，
// 继承 AudioServiceActivity 即可，它本身就是 FlutterActivity。
class MainActivity : AudioServiceActivity() {
    private var splashOverlay: FrameLayout? = null
    private var splashAnimation: LottieAnimationView? = null
    private var splashStarted = false
    private val handler = Handler(Looper.getMainLooper())
    private val splashFallback = Runnable { startSplashAnimation() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 首帧之前声明，避免先以 60Hz 起一屏再切到高刷
        DisplayRefreshRate.requestMax(this)
        // 只在真正的冷启动挂闪屏；转屏 / 系统重建不该再盖一次
        if (savedInstanceState == null) {
            installSplashOverlay()
        }
    }

    override fun onResume() {
        super.onResume()
        // 回到前台时系统会重新按策略选显示模式，这里再声明一次
        DisplayRefreshRate.requestMax(this)
    }

    /**
     * 首帧显示的回调，在这里才开始播动画。
     *
     * 别用 `addOnPreDrawListener`：覆盖层自己 addView 就会触发 preDraw，
     * 那时系统启动屏还没撤，动画会白跑一段；而且等 preDraw 再挂覆盖层，
     * 首页会先露一下才被盖上。正确顺序是「onCreate 先挂静态层 → 首帧显示 → 起播」。
     */
    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        startSplashAnimation()
    }

    /**
     * 在 Flutter 内容之上盖一层全屏纯色 + 居中 Lottie 的覆盖层。
     *
     * 一挂上就挡住首页（所以首页不会先露出来），但先不播；等首帧显示后再起播，
     * 动画的起跑时刻和用户真正看到的时刻对齐。
     */
    private fun installSplashOverlay() {
        val root = findViewById<ViewGroup>(android.R.id.content) ?: return
        if (root.findViewById<FrameLayout>(R.id.splash_overlay) != null) {
            return
        }

        val background = ContextCompat.getColor(this, R.color.splash_background)
        val tint = ContextCompat.getColor(this, R.color.splash_logo_tint)

        val overlay = FrameLayout(this).apply {
            id = R.id.splash_overlay
            setBackgroundColor(background)
            // 盖住期间别让点击穿透到下面的首页
            isClickable = true
        }

        val size = (SPLASH_LOGO_BASE_DP * resources.displayMetrics.density).toInt()
        val animation = LottieAnimationView(this).apply {
            setAnimation(R.raw.netease_loading)
            // 与第 42 帧对齐：轮廓长满就停，后面的呼吸段闪屏用不到
            setMinAndMaxFrame(0, SPLASH_END_FRAME)
            repeatCount = 0
            // Lottie 按 composition 的 132dp 原尺寸绘制，不跟随 View 大小
            // （CENTER_INSIDE 实测 70dp 一小坨，FIT_CENTER 直接画没了）。
            // 所以 View 保持 132dp，用 scale 放大，行为最可预测。
            scaleType = ImageView.ScaleType.CENTER_INSIDE
            scaleX = SPLASH_LOGO_SCALE
            scaleY = SPLASH_LOGO_SCALE
            // 动画里只有一条黑色描边（两处 stroke），整体染色；
            // 深色底必须换白，否则 10% 黑叠在 #121212 上等于隐形
            addValueCallback(
                KeyPath("**"),
                LottieProperty.STROKE_COLOR,
                LottieValueCallback(tint),
            )
        }

        overlay.addView(
            animation,
            FrameLayout.LayoutParams(size, size, Gravity.CENTER),
        )
        root.addView(
            overlay,
            ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )

        splashOverlay = overlay
        splashAnimation = animation
        // 兜底：onFlutterUiDisplayed 万一没来（engine 复用等），别把用户永远挡在闪屏上
        handler.postDelayed(splashFallback, SPLASH_TIMEOUT_MS)
    }

    private fun startSplashAnimation() {
        if (splashStarted) {
            return
        }
        val animation = splashAnimation ?: return
        val overlay = splashOverlay ?: return
        splashStarted = true
        handler.removeCallbacks(splashFallback)
        animation.playAnimation()
        animation.addAnimatorListener(
            object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    if (isFinishing || isDestroyed) {
                        return
                    }
                    overlay.animate()
                        .alpha(0f)
                        .setDuration(FADE_OUT_MS)
                        .withEndAction { (overlay.parent as? ViewGroup)?.removeView(overlay) }
                        .start()
                }
            },
        )
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    private companion object {
        /**
         * Lottie composition 的原始尺寸（dp）。
         *
         * 不改这个值：Lottie 按 composition 尺寸绘制，改 View 尺寸不生效，
         * 放大靠 [SPLASH_LOGO_SCALE]。
         */
        const val SPLASH_LOGO_BASE_DP = 132

        /**
         * 放大倍数。
         *
         * 图形本身只占 composition 的 47%（路径 ±68 × 图层 46% 缩放），
         * 132dp 画布下音符只有 62dp；×1.7 后约 105dp，占 406dp 屏宽的 26%。
         */
        const val SPLASH_LOGO_SCALE = 1.7f
        const val SPLASH_END_FRAME = 42
        const val FADE_OUT_MS = 250L
        const val SPLASH_TIMEOUT_MS = 3000L
    }
}
