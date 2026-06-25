plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.flutter_application_1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // AGP 9+ 默认关闭 resValue，启用后才能用 defaultConfig.resValue 注入应用名
    buildFeatures {
        resValues = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        // Flutter 测试包名；与原版 com.lstech.lprobot 并存，避免签名冲突导致无法安装。
        // 正式替换原版 APK 时需卸载旧版并使用同一签名证书，再改回 com.lstech.lprobot。
        applicationId = "com.example.flutter_application_1"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        resValue("string", "app_name", "领鹏智能 ${flutter.versionName}")
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

// Android 无 exe 旁 dll/：构建前将 dll/visualprogram 打成加密 LPK 并写入 Flutter assets。
// 运行时：APK 内嵌 assets/blockly/visualprogram.lpk → 首次进编程页解压到 installRoot/dll/visualprogram/
val syncBlocklyAssets = tasks.register<Exec>("syncBlocklyAssets") {
    val projectRoot = rootProject.projectDir.parentFile.parentFile
    workingDir = projectRoot
    commandLine("dart", "run", "tool/sync_blockly_assets.dart")
    onlyIf { File(projectRoot, "dll/visualprogram").exists() }
}

val packageBlocklyLpk = tasks.register<Exec>("packageBlocklyLpk") {
    val projectRoot = rootProject.projectDir.parentFile.parentFile
    workingDir = projectRoot
    commandLine("dart", "run", "tool/package_blockly_lpk.dart")
    dependsOn(syncBlocklyAssets)
    onlyIf { File(projectRoot, "dll/visualprogram").exists() }
}

tasks.named("preBuild").configure {
    dependsOn(packageBlocklyLpk)
}
