package com.example.meow

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.concurrent.Executors

/** Saves to the gallery on Android 10+, or lets the user choose a file on older devices. */
class ImageSaver(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private val executor = Executors.newSingleThreadExecutor()
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "savePng") {
            result.notImplemented()
            return
        }
        val bytes = call.arguments as? ByteArray
        if (bytes == null || bytes.isEmpty()) {
            result.error("INVALID_IMAGE", "图片数据无效", null)
            return
        }
        if (pendingResult != null) {
            result.error("SAVE_IN_PROGRESS", "图片正在保存", null)
            return
        }
        pendingResult = result
        val filename = "meow-community-${System.currentTimeMillis()}.png"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            executor.execute {
                var uri: Uri? = null
                try {
                    val values = ContentValues().apply {
                        put(MediaStore.Images.Media.DISPLAY_NAME, filename)
                        put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                        put(MediaStore.Images.Media.RELATIVE_PATH, "${Environment.DIRECTORY_PICTURES}/Meow")
                        put(MediaStore.Images.Media.IS_PENDING, 1)
                    }
                    val resolver = activity.contentResolver
                    uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                        ?: throw IOException("Unable to create image")
                    writeImage(uri, bytes)
                    values.clear()
                    values.put(MediaStore.Images.Media.IS_PENDING, 0)
                    if (resolver.update(uri, values, null, null) == 0) {
                        throw IOException("Unable to publish image")
                    }
                    activity.runOnUiThread { finish("gallery") }
                } catch (_: Exception) {
                    uri?.let { runCatching { activity.contentResolver.delete(it, null, null) } }
                    activity.runOnUiThread { fail() }
                }
            }
        } else {
            pendingBytes = bytes
            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
                .addCategory(Intent.CATEGORY_OPENABLE)
                .setType("image/png")
                .putExtra(Intent.EXTRA_TITLE, filename)
            try {
                activity.startActivityForResult(intent, SAVE_REQUEST_CODE)
            } catch (_: ActivityNotFoundException) {
                fail()
            }
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != SAVE_REQUEST_CODE) return false
        val bytes = pendingBytes ?: return true
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            finish("canceled")
            return true
        }
        executor.execute {
            try {
                writeImage(uri, bytes)
                activity.runOnUiThread { finish("file") }
            } catch (_: Exception) {
                runCatching { activity.contentResolver.delete(uri, null, null) }
                activity.runOnUiThread { fail() }
            }
        }
        return true
    }

    private fun writeImage(uri: Uri, bytes: ByteArray) {
        val stream = activity.contentResolver.openOutputStream(uri)
            ?: throw IOException("Unable to open image")
        stream.use { it.write(bytes) }
    }

    private fun finish(destination: String) {
        val result = pendingResult
        pendingResult = null
        pendingBytes = null
        result?.success(destination)
    }

    private fun fail() {
        val result = pendingResult
        pendingResult = null
        pendingBytes = null
        result?.error("SAVE_FAILED", "图片保存失败，请重试", null)
    }

    fun detach() {
        pendingResult?.error("SAVE_INTERRUPTED", "保存已中断，请重试", null)
        pendingResult = null
        pendingBytes = null
        executor.shutdown()
    }

    companion object {
        private const val SAVE_REQUEST_CODE = 7542
    }
}
