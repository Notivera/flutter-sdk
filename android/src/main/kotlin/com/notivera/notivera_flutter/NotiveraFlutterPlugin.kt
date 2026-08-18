package com.notivera.notivera_flutter

import android.app.Activity
import android.app.Application
import androidx.lifecycle.Observer
import com.notivera.sdk.SDK
import com.notivera.sdk.SDKConfig
import com.notivera.sdk.SDKResponse
import com.notivera.sdk.ConnectionType as SdkConnectionType
import com.notivera.sdk.business.data.EventType as SdkEventType
import com.notivera.sdk.business.data.PushEvent as SdkPushEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class NotiveraFlutterPlugin :
    FlutterPlugin,
    ActivityAware,
    NotiveraHostApi {
    private var application: Application? = null
    private var activity: Activity? = null
    private var flutterApi: NotiveraFlutterApi? = null
    private var eventObserver: Observer<SdkPushEvent>? = null
    private var initialized = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        application = binding.applicationContext as Application
        flutterApi = NotiveraFlutterApi(binding.binaryMessenger)
        NotiveraHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        eventObserver?.let { SDK.pushEvent.removeObserver(it) }
        eventObserver = null
        NotiveraHostApi.setUp(binding.binaryMessenger, null)
        flutterApi = null
        application = null
        initialized = false
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun initialize(config: NotiveraConfig) {
        val app =
            application
                ?: throw FlutterError("no-application", "Flutter engine is not attached.", null)
        SDK.init(app, config.toSdk())
        initialized = true
        ensureEventObserver()
    }

    override fun getDeviceId(): String? {
        requireInitialized()
        return SDK.getDeviceId()
    }

    override fun getCustomerId(): String? {
        requireInitialized()
        val id = SDK.getCustomerId()
        return id.ifEmpty { null }
    }

    override fun setCustomerId(customerId: String) {
        requireInitialized()
        SDK.setCustomerId(customerId)
    }

    override fun getSdkVersion(): String? = null

    override fun subscribeTag(
        tag: String,
        callback: (Result<String>) -> Unit,
    ) {
        invokeAsync(callback) { SDK.subscribeTag(tag, it) }
    }

    override fun unsubscribeTag(
        tag: String,
        callback: (Result<String>) -> Unit,
    ) {
        invokeAsync(callback) { SDK.unsubscribeTag(tag, it) }
    }

    override fun updatePersonalisationVariables(
        entries: List<PersonalisationEntry>,
        callback: (Result<String>) -> Unit,
    ) {
        val schema = entries.associate { it.name to it.value }
        invokeAsync(callback) { SDK.updatePersonalisationVariables(schema, it) }
    }

    override fun getAllPersonalisations(): List<PersonalisationEntry> {
        requireInitialized()
        return SDK.getAllPersonalisations().map { (name, value) ->
            PersonalisationEntry(name = name, value = value)
        }
    }

    override fun showInAppNotification(
        customIdentifier: String,
        callback: (Result<String>) -> Unit,
    ) {
        invokeAsync(callback) { SDK.showInAppNotification(customIdentifier, it) }
    }

    override fun closeNotificationView() {
        requireInitialized()
        SDK.closeNotificationView()
    }

    override fun requestAuthorisationPrompts(callback: (Result<Unit>) -> Unit) {
        val current =
            activity ?: run {
                callback(
                    Result.failure(
                        FlutterError("no-activity", "No Android Activity is attached.", null),
                    ),
                )
                return
            }
        try {
            requireInitialized()
            SDK.requestGeofencePermission(current)
            callback(Result.success(Unit))
        } catch (error: Throwable) {
            callback(Result.failure(error))
        }
    }

    override fun setPushToken(token: String) {
        requireInitialized()
        SDK.setFCMToken(token)
    }

    override fun isNotiveraMessage(data: Map<String, String>): Boolean {
        requireInitialized()
        return SDK.isNotiveraMessage(data)
    }

    override fun handlePushMessage(data: Map<String, String>) {
        requireInitialized()
        SDK.handlePushMessage(data)
    }

    private fun invokeAsync(
        callback: (Result<String>) -> Unit,
        call: (SDKResponse<String>) -> Unit,
    ) {
        try {
            requireInitialized()
            call(
                object : SDKResponse<String> {
                    override fun onSuccess(result: String) {
                        callback(Result.success(result))
                    }

                    override fun onError(throwable: Throwable) {
                        callback(
                            Result.failure(
                                FlutterError("sdk-error", throwable.message, null),
                            ),
                        )
                    }
                },
            )
        } catch (error: Throwable) {
            callback(Result.failure(error))
        }
    }

    private fun requireInitialized() {
        if (!initialized) {
            throw FlutterError(
                "not-initialized",
                "Call initialize() before using the Notivera SDK.",
                null,
            )
        }
    }

    private fun ensureEventObserver() {
        if (eventObserver != null) {
            return
        }
        val observer =
            Observer<SdkPushEvent> { event ->
                flutterApi?.onPushEvent(event.toPigeon()) { }
            }
        eventObserver = observer
        SDK.pushEvent.observeForever(observer)
    }
}

private fun NotiveraConfig.toSdk(): SDKConfig =
    SDKConfig(
        apiKey = apiKey,
        apiSecret = apiSecret,
        tenantID = tenantId,
        appVersion = appVersion,
        customerId = customerId,
        downloadConnectionType = downloadConnectionType.toSdk(),
        enableDebug = enableDebug ?: false,
        trackLocation = trackLocation ?: false,
        enableGeofence = enableGeofence ?: false,
        inAppOpenDelay = inAppOpenDelayMs,
    )

private fun ConnectionType?.toSdk(): SdkConnectionType =
    when (this) {
        ConnectionType.WIFI -> SdkConnectionType.WIFI
        ConnectionType.MOBILE -> SdkConnectionType.MOBILE
        ConnectionType.MOBILE_ROAMING -> SdkConnectionType.MOBILE_ROAMING
        ConnectionType.MOBILE_NO_ROAMING -> SdkConnectionType.MOBILE_NO_ROAMING
        ConnectionType.ALL, null -> SdkConnectionType.ALL
    }

private fun SdkPushEvent.toPigeon(): PushEvent =
    PushEvent(
        id = id,
        eventType = eventType.toPigeon(),
        title = title,
        description = description,
        replacements = replacements,
        message = message,
        clientMetadata = clientMetadata,
        type = type,
        targetUrl = targetUrl,
    )

private fun SdkEventType?.toPigeon(): EventType? =
    when (this) {
        SdkEventType.NOTIFICATION_TAPPED -> EventType.NOTIFICATION_TAPPED
        SdkEventType.VIDEO_CLOSED -> EventType.VIDEO_CLOSED
        SdkEventType.IN_APP_CLOSED -> EventType.IN_APP_CLOSED
        SdkEventType.IN_APP_CTA_TAPPED -> EventType.IN_APP_CTA_TAPPED
        null -> null
    }
