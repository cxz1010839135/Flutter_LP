package com.example.flutter_application_1

import android.Manifest
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.View
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * 横屏 + 联机时常亮；隐藏系统状态栏。
 * 网络通道对齐老项目 ConnectActivity/HttpManager：Wi‑Fi 绑定 + OkHttp 直连控制器。
 */
class MainActivity : FlutterActivity() {
    companion object {
        private const val NETWORK_CHANNEL = "com.lstech.lprobot/network"
        private const val STORAGE_CHANNEL = "com.lstech.lprobot/storage"
        private const val REQ_MANAGE_STORAGE = 4101
        private const val REQ_LEGACY_STORAGE = 4102
        private const val REQ_WIFI_SSID = 4103
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val ioExecutor = Executors.newCachedThreadPool()
    private var pendingStorageResult: MethodChannel.Result? = null
    private var pendingWifiSsidResult: MethodChannel.Result? = null
    private var awaitingStorageSettings = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        hideSystemUi()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "bindWifiNetwork" -> {
                        ioExecutor.execute {
                            val ok = try {
                                RobotWifiHttp.ensureWifiBound(applicationContext)
                            } catch (_: Exception) {
                                false
                            }
                            mainHandler.post {
                                // 对齐老项目：绑定失败不阻断，仍允许后续直连尝试
                                result.success(ok)
                            }
                        }
                    }
                    "unbindNetwork" -> {
                        ioExecutor.execute {
                            RobotWifiHttp.unbind(applicationContext)
                            mainHandler.post { result.success(null) }
                        }
                    }
                    "getWifiSsid" -> {
                        result.success(RobotWifiHttp.currentWifiSsid(applicationContext))
                    }
                    "isWifiConnected" -> {
                        result.success(RobotWifiHttp.isWifiConnected(applicationContext))
                    }
                    "ensureWifiSsidPermission" -> {
                        ensureWifiSsidPermission(result)
                    }
                    "httpPost" -> {
                        val url = call.argument<String>("url")
                        val body = call.argument<ByteArray>("body")
                        val contentType = call.argument<String>("contentType")
                            ?: "application/json; charset=utf-8"
                        val connectTimeoutMs =
                            call.argument<Number>("connectTimeoutMs")?.toLong() ?: 30_000L
                        val readTimeoutMs =
                            call.argument<Number>("readTimeoutMs")?.toLong() ?: 45_000L
                        if (url.isNullOrBlank() || body == null) {
                            result.error("ARG", "url/body 不能为空", null)
                            return@setMethodCallHandler
                        }
                        ioExecutor.execute {
                            try {
                                val text = RobotWifiHttp.httpPost(
                                    applicationContext,
                                    url,
                                    body,
                                    contentType,
                                    connectTimeoutMs,
                                    readTimeoutMs,
                                )
                                mainHandler.post { result.success(text) }
                            } catch (e: Exception) {
                                mainHandler.post {
                                    result.error(
                                        "HTTP",
                                        e.message ?: "网络请求失败",
                                        null,
                                    )
                                }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasAllFilesAccess" -> result.success(hasAllFilesAccess())
                    "requestAllFilesAccess" -> requestAllFilesAccess(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasAllFilesAccess(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            val read = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.READ_EXTERNAL_STORAGE,
            ) == PackageManager.PERMISSION_GRANTED
            val write = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.WRITE_EXTERNAL_STORAGE,
            ) == PackageManager.PERMISSION_GRANTED
            read || write
        }
    }

    private fun requestAllFilesAccess(result: MethodChannel.Result) {
        if (hasAllFilesAccess()) {
            result.success(true)
            return
        }
        // 上一轮设置页返回未回调时，先结束挂起请求，避免 Future 永久等待
        if (pendingStorageResult != null) {
            finishPendingStorage(hasAllFilesAccess())
        }
        pendingStorageResult = result
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            awaitingStorageSettings = true
            try {
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION).apply {
                    data = Uri.parse("package:$packageName")
                }
                @Suppress("DEPRECATION")
                startActivityForResult(intent, REQ_MANAGE_STORAGE)
            } catch (_: Exception) {
                try {
                    val fallback = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                    @Suppress("DEPRECATION")
                    startActivityForResult(fallback, REQ_MANAGE_STORAGE)
                } catch (_: Exception) {
                    awaitingStorageSettings = false
                    finishPendingStorage(false)
                }
            }
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE,
                ),
                REQ_LEGACY_STORAGE,
            )
        }
    }

    private fun finishPendingStorage(granted: Boolean) {
        awaitingStorageSettings = false
        pendingStorageResult?.success(granted)
        pendingStorageResult = null
    }

    private fun ssidPermissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                Manifest.permission.NEARBY_WIFI_DEVICES,
                Manifest.permission.ACCESS_FINE_LOCATION,
            )
        } else {
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            )
        }
    }

    private fun hasSsidPermission(): Boolean {
        return ssidPermissions().any {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun ensureWifiSsidPermission(result: MethodChannel.Result) {
        if (hasSsidPermission()) {
            result.success(true)
            return
        }
        if (pendingWifiSsidResult != null) {
            pendingWifiSsidResult?.success(hasSsidPermission())
            pendingWifiSsidResult = null
        }
        pendingWifiSsidResult = result
        ActivityCompat.requestPermissions(this, ssidPermissions(), REQ_WIFI_SSID)
    }

    private fun finishPendingWifiSsid(granted: Boolean) {
        pendingWifiSsidResult?.success(granted)
        pendingWifiSsidResult = null
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_MANAGE_STORAGE) {
            finishPendingStorage(hasAllFilesAccess())
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_LEGACY_STORAGE) {
            finishPendingStorage(hasAllFilesAccess())
        } else if (requestCode == REQ_WIFI_SSID) {
            finishPendingWifiSsid(hasSsidPermission())
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            hideSystemUi()
        }
    }

    override fun onResume() {
        super.onResume()
        hideSystemUi()
        // 从系统设置返回：无论是否授权都结束挂起的权限请求
        if (awaitingStorageSettings && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            finishPendingStorage(hasAllFilesAccess())
        }
    }

    override fun onDestroy() {
        RobotWifiHttp.unbind(applicationContext)
        awaitingStorageSettings = false
        pendingStorageResult = null
        pendingWifiSsidResult = null
        super.onDestroy()
    }

    /**
     * 沉浸隐藏系统栏，但不在导航栏区域做 layout（去掉 LAYOUT_HIDE_NAVIGATION）。
     * 部分平板虚拟键无法常隐时，Flutter 仍能收到正确 viewPadding，底部不被遮挡。
     */
    private fun hideSystemUi() {
        WindowCompat.setDecorFitsSystemWindows(window, true)
        val controller = WindowCompat.getInsetsController(window, window.decorView)
        controller?.let {
            it.hide(WindowInsetsCompat.Type.systemBars())
            it.systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                )
        }
    }
}
