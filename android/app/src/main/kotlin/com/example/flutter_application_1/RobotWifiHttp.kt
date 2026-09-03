package com.example.flutter_application_1

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.wifi.WifiInfo
import android.net.wifi.WifiManager
import android.os.Build
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.util.concurrent.TimeUnit

/**
 * 对齐老版 [HttpManager] + 现代 Android Wi‑Fi 路由：
 * - 老项目 targetSdk=28，连机器人热点后 OkHttp 直连 192.168.11.11 即可
 * - 新系统常把无外网 Wi‑Fi 降为非默认网，需 bind + 使用该 Network 的 socketFactory
 */
object RobotWifiHttp {
    @Volatile
    private var boundNetwork: Network? = null

    @Volatile
    private var wifiClient: OkHttpClient? = null

    fun isWifiConnected(context: Context): Boolean {
        return try {
            val cm =
                context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            findWifiNetwork(cm) != null
        } catch (_: Exception) {
            false
        }
    }

    fun currentWifiSsid(context: Context): String {
        return try {
            val fromTransport = ssidFromTransport(context)
            if (fromTransport.isNotEmpty()) return fromTransport
            @Suppress("DEPRECATION")
            val wm =
                context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val fromManager = sanitizeSsid(wm.connectionInfo?.ssid)
            if (fromManager.isNotEmpty()) return fromManager
            ssidFromNetworkInfo(context)
        } catch (_: Exception) {
            ""
        }
    }

    private fun ssidFromTransport(context: Context): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return ""
        val cm =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        for (network in cm.allNetworks) {
            val caps = cm.getNetworkCapabilities(network) ?: continue
            if (!caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) continue
            val info = caps.transportInfo as? WifiInfo ?: continue
            val ssid = sanitizeSsid(info.ssid)
            if (ssid.isNotEmpty()) return ssid
        }
        return ""
    }

    @Suppress("DEPRECATION")
    private fun ssidFromNetworkInfo(context: Context): String {
        val cm =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val info = cm.getNetworkInfo(ConnectivityManager.TYPE_WIFI)
        return sanitizeSsid(info?.extraInfo)
    }

    private fun sanitizeSsid(raw: String?): String {
        if (raw.isNullOrBlank()) return ""
        val s = raw.trim().trim('"')
        if (s.isEmpty() ||
            s.equals("<unknown ssid>", ignoreCase = true) ||
            s.equals("<none>", ignoreCase = true) ||
            s == "0x"
        ) {
            return ""
        }
        return s
    }

    fun ensureWifiBound(context: Context): Boolean {
        val cm =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = findWifiNetwork(cm) ?: return false
        val ok = cm.bindProcessToNetwork(network)
        if (!ok) return false
        boundNetwork = network
        wifiClient = OkHttpClient.Builder()
            .socketFactory(network.socketFactory)
            .connectTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(45, TimeUnit.SECONDS)
            .readTimeout(45, TimeUnit.SECONDS)
            .retryOnConnectionFailure(true)
            .build()
        return true
    }

    fun unbind(context: Context) {
        val cm =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        try {
            cm.bindProcessToNetwork(null)
        } catch (_: Exception) {
        }
        boundNetwork = null
        wifiClient = null
    }

    /**
     * 对齐老版 HttpManager.postJson：POST body，返回响应字符串。
     * 优先走已绑定 Wi‑Fi 的 OkHttp；未绑定时再尝试绑定后发送。
     */
    fun httpPost(
        context: Context,
        url: String,
        body: ByteArray,
        contentType: String,
        connectTimeoutMs: Long,
        readTimeoutMs: Long,
    ): String {
        var client = wifiClient
        if (client == null) {
            ensureWifiBound(context)
            client = wifiClient
        }
        if (client == null) {
            // 与老项目一致：即使绑定失败也尝试默认 OkHttp 直连
            client = OkHttpClient.Builder()
                .connectTimeout(connectTimeoutMs, TimeUnit.MILLISECONDS)
                .writeTimeout(readTimeoutMs, TimeUnit.MILLISECONDS)
                .readTimeout(readTimeoutMs, TimeUnit.MILLISECONDS)
                .retryOnConnectionFailure(true)
                .build()
        } else if (
            connectTimeoutMs != 30_000L || readTimeoutMs != 45_000L
        ) {
            client = client.newBuilder()
                .connectTimeout(connectTimeoutMs, TimeUnit.MILLISECONDS)
                .writeTimeout(readTimeoutMs, TimeUnit.MILLISECONDS)
                .readTimeout(readTimeoutMs, TimeUnit.MILLISECONDS)
                .build()
        }

        val media = contentType.toMediaType()
        val request = Request.Builder()
            .url(url)
            .post(body.toRequestBody(media))
            .build()

        client.newCall(request).execute().use { response ->
            val text = response.body?.string().orEmpty()
            if (!response.isSuccessful) {
                throw java.io.IOException("HTTP ${response.code}${if (text.isEmpty()) "" else " · $text"}")
            }
            return text
        }
    }

    private fun findWifiNetwork(cm: ConnectivityManager): Network? {
        val active = cm.activeNetwork
        val activeCaps = cm.getNetworkCapabilities(active)
        if (active != null &&
            activeCaps != null &&
            activeCaps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
        ) {
            return active
        }
        @Suppress("DEPRECATION")
        for (network in cm.allNetworks) {
            val caps = cm.getNetworkCapabilities(network) ?: continue
            if (caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                return network
            }
        }
        return null
    }
}
