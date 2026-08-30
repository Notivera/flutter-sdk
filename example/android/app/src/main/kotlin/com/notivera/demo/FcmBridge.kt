package com.notivera.demo

import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges native FCM callbacks to the example app's Dart MethodChannel.
 * Queues events until Flutter attaches a channel and calls [ready].
 */
object FcmBridge {
    private const val TAG = "NotiveraDemoFcm"

    const val CHANNEL = "com.notivera.demo/fcm"

    @Volatile
    private var channel: MethodChannel? = null

    @Volatile
    private var dartReady = false

    private val mainHandler = Handler(Looper.getMainLooper())
    private val pending = mutableListOf<Pair<String, Any?>>()

    fun attach(channel: MethodChannel) {
        this.channel = channel
        Log.d(TAG, "MethodChannel attached")
    }

    fun detach() {
        channel = null
        dartReady = false
        Log.d(TAG, "MethodChannel detached")
    }

    fun markReady() {
        dartReady = true
        flushPending()
    }

    fun send(
        method: String,
        arguments: Any?,
    ) {
        mainHandler.post {
            if (dartReady && channel != null) {
                Log.d(TAG, "invokeMethod $method")
                channel?.invokeMethod(method, arguments)
            } else {
                Log.d(TAG, "queue $method (dartReady=$dartReady hasChannel=${channel != null})")
                pending.add(method to arguments)
            }
        }
    }

    private fun flushPending() {
        val ch = channel ?: return
        if (!dartReady) return
        val copy = pending.toList()
        pending.clear()
        for ((method, args) in copy) {
            Log.d(TAG, "flush invokeMethod $method")
            ch.invokeMethod(method, args)
        }
    }
}
