package com.notivera.demo

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class DemoFirebaseMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        Log.d(TAG, "onNewToken length=${token.length}")
        FcmBridge.send("onToken", token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val data = message.data
        Log.d(
            TAG,
            "onMessageReceived messageId=${message.messageId} dataKeys=${data.keys}",
        )
        if (data.isEmpty()) {
            Log.d(TAG, "onMessageReceived skipped: empty data")
            return
        }
        FcmBridge.send("onMessage", HashMap(data))
    }

    companion object {
        private const val TAG = "NotiveraDemoFcm"
    }
}
