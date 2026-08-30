package com.notivera.demo

import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel =
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                FcmBridge.CHANNEL,
            )
        FcmBridge.attach(channel)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "ready" -> {
                    FcmBridge.markReady()
                    result.success(null)
                }
                "getToken" -> {
                    FirebaseMessaging.getInstance().token
                        .addOnCompleteListener { task ->
                            if (!task.isSuccessful) {
                                val error = task.exception
                                Log.e(TAG, "getToken failed", error)
                                result.error(
                                    "TOKEN",
                                    error?.message ?: "Failed to get FCM token",
                                    null,
                                )
                                return@addOnCompleteListener
                            }
                            result.success(task.result)
                        }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        deliverNotificationOpen(intent, source = "onCreate")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        deliverNotificationOpen(intent, source = "onNewIntent")
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        FcmBridge.detach()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun deliverNotificationOpen(
        intent: Intent?,
        source: String,
    ) {
        val extras = intent?.extras ?: return
        val data = HashMap<String, String>()
        for (key in extras.keySet()) {
            if (key.startsWith("google.") || key.startsWith("gcm.") || key == "from") {
                continue
            }
            val value = extras.get(key)?.toString() ?: continue
            data[key] = value
        }
        if (data.isEmpty()) {
            return
        }
        Log.d(TAG, "notification open from=$source dataKeys=${data.keys}")
        FcmBridge.send("onMessageOpened", data)
    }

    companion object {
        private const val TAG = "NotiveraDemoFcm"
    }
}
