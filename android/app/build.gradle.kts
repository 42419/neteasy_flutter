plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "top.yunov.neteasy_flutter"
    compileSdk = flutter.compileSdkVersion
    // 不设 ndkVersion：本项目没有 native 源码，NDK 只会被 AGP 用来 strip 预编译的
    // libneteasy_backend.so，却要为此下载约 1GB 的 NDK（CI 上就是卡在这一步）。
    // 配套的 packaging.jniLibs.keepDebugSymbols 让 AGP 跳过 strip。

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    packaging {
        jniLibs {
            // 后端库是 release 版 Rust 产物，符号已剥离，不需要 AGP 再 strip
            keepDebugSymbols += "**/*.so"
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "top.yunov.neteasy_flutter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // BackendService 用到 NotificationCompat / ServiceCompat.startForeground(type)
    implementation("androidx.core:core-ktx:1.16.0")
}
