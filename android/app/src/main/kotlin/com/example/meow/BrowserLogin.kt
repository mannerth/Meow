package com.example.meow

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Opens the user's default browser and receives the existing backend's meow callback. */
class BrowserLogin(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private val preferences = activity.getSharedPreferences("browser_login", Context.MODE_PRIVATE)
    private val handler = Handler(Looper.getMainLooper())
    private var pendingResult: MethodChannel.Result? = null
    private var queuedCallback: Map<String, Any>? = null
    private val timeout = Runnable { fail("TIMED_OUT", "登录超时，请重试") }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "authenticate" -> authenticate(call, result)
            "hasPendingLogin" -> result.success(hasPendingLogin())
            "resumeLogin" -> {
                val active = hasPendingLogin()
                if (pendingResult != null) {
                    result.error("LOGIN_IN_PROGRESS", "已有登录正在进行", null)
                } else if (!active) {
                    result.error("SESSION_EXPIRED", "登录已过期，请重试", null)
                } else {
                    pendingResult = result
                    val callback = queuedCallback
                    if (callback != null) complete(callback) else scheduleTimeout()
                }
            }
            "cancelLogin" -> {
                fail("CANCELED", "已取消登录")
                result.success(null)
            }
            "openDefaultBrowserSettings" -> {
                try {
                    activity.startActivity(Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS))
                    result.success(null)
                } catch (_: ActivityNotFoundException) {
                    result.error("SETTINGS_UNAVAILABLE", "请在系统设置中选择默认浏览器", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun authenticate(call: MethodCall, result: MethodChannel.Result) {
        if (hasPendingLogin() || pendingResult != null) {
            result.error("LOGIN_IN_PROGRESS", "已有登录正在进行", null)
            return
        }
        val url = call.argument<String>("url")?.let(Uri::parse)
        if (url == null || url.scheme != "https" || url.host != "meow.sduonline.cn") {
            result.error("INVALID_URL", "登录地址无效", null)
            return
        }

        // Store only the pending session metadata; never persist callback URLs or tokens here.
        val saved = preferences.edit()
            .putLong("expiresAt", System.currentTimeMillis() + SESSION_DURATION_MS)
            .putBoolean("isAdmin", call.argument<Boolean>("isAdmin") ?: false)
            .commit()
        if (!saved) {
            result.error("SESSION_UNAVAILABLE", "无法保存登录状态，请重试", null)
            return
        }
        pendingResult = result
        scheduleTimeout()
        val intent = Intent(Intent.ACTION_VIEW, url)
            .addCategory(Intent.CATEGORY_BROWSABLE)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        // Let Android apply the user's browser preference, without querying packages:
        // OEM resolver activities and package visibility can make preflight checks fail.
        // A hostless selector matches HTTPS browsers, excluding domain-specific App Links.
        // Only resolution uses the selector; the browser receives the original login URL.
        // If no default exists, Android lets the user choose a browser itself.
        intent.selector = Intent(Intent.ACTION_VIEW, Uri.parse("https:"))
            .addCategory(Intent.CATEGORY_BROWSABLE)
        try {
            activity.startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            fail("BROWSER_UNAVAILABLE", "无法打开浏览器，请检查浏览器是否已安装、启用及设为默认")
        } catch (_: SecurityException) {
            fail("BROWSER_UNAVAILABLE", "无法打开默认浏览器，请检查系统设置")
        }
    }

    fun handleCallback(uri: Uri?) {
        if (uri?.scheme != "meow" || !hasPendingLogin()) return
        val callback = mapOf<String, Any>(
            "url" to uri.toString(),
            "isAdmin" to preferences.getBoolean("isAdmin", false),
        )
        if (pendingResult != null) complete(callback) else queuedCallback = callback
    }

    private fun hasPendingLogin(): Boolean {
        val active = preferences.getLong("expiresAt", 0) > System.currentTimeMillis()
        if (!active) {
            fail("TIMED_OUT", "登录超时，请重试")
        }
        return active
    }

    private fun scheduleTimeout() {
        handler.removeCallbacks(timeout)
        handler.postDelayed(timeout, (preferences.getLong("expiresAt", 0) - System.currentTimeMillis()).coerceAtLeast(0))
    }

    private fun complete(callback: Map<String, Any>) {
        val result = pendingResult
        clearSession()
        result?.success(callback)
    }

    private fun fail(code: String, message: String) {
        val result = pendingResult
        clearSession()
        result?.error(code, message, null)
    }

    private fun clearSession() {
        handler.removeCallbacks(timeout)
        pendingResult = null
        queuedCallback = null
        preferences.edit().clear().commit()
    }

    fun detach() {
        handler.removeCallbacks(timeout)
        pendingResult?.error("SESSION_INTERRUPTED", "登录页面已关闭，请重新登录", null)
        pendingResult = null
    }

    companion object {
        private const val SESSION_DURATION_MS = 10 * 60 * 1000L
    }
}
