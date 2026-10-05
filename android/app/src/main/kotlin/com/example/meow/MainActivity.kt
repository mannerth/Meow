package com.example.meow

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var browserLogin: BrowserLogin
    private lateinit var imageSaver: ImageSaver

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        browserLogin = BrowserLogin(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "meow/browser_login")
            .setMethodCallHandler(browserLogin)
        imageSaver = ImageSaver(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "meow/image_saver")
            .setMethodCallHandler(imageSaver)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        receiveLoginCallback(intent)
    }

    override fun onNewIntent(intent: Intent) {
        // The login callback is consumed by our channel, rather than Flutter's route handler.
        receiveLoginCallback(intent)
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun receiveLoginCallback(intent: Intent) {
        if (intent.data?.scheme == "meow") {
            browserLogin.handleCallback(intent.data)
            intent.data = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (imageSaver.onActivityResult(requestCode, resultCode, data)) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        browserLogin.detach()
        imageSaver.detach()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "meow/browser_login")
            .setMethodCallHandler(null)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "meow/image_saver")
            .setMethodCallHandler(null)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
