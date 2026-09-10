package com.example.mobile_app

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "sahakaar_seva/upi"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchUpi") {
                val uriString = call.argument<String>("uri")
                if (uriString != null) {
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uriString))
                        val chooser = Intent.createChooser(intent, "Pay with UPI")
                        startActivity(chooser)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uriString))
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("UPI_LAUNCH_FAILED", e2.message, null)
                        }
                    }
                } else {
                    result.error("INVALID_URI", "URI string is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
