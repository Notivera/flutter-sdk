package com.notivera.notivera_flutter

import android.app.Activity
import android.app.Application
import android.content.Context
import android.util.Log
import androidx.lifecycle.Observer
import com.notivera.sdk.SDK
import com.notivera.sdk.SDKConfig
import com.notivera.sdk.SDKResponse
import com.notivera.sdk.NotiveraPushTheme as SdkNotiveraPushTheme
import com.notivera.sdk.ConnectionType as SdkConnectionType
import com.notivera.sdk.business.data.EventType as SdkEventType
import com.notivera.sdk.business.data.PushEvent as SdkPushEvent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.UnknownHostException
import java.util.regex.Pattern

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
        // pushTheme is Android-only (ignored on iOS). Resource names resolve to R.drawable/mipmap/color.
        SDK.init(app, config.toSdk(), config.toPushTheme(app))
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
        invokeAsync(callback, operation = "subscribeTag", context = mapOf("tag" to tag)) {
            Log.d(TAG, "subscribeTag requested tag=$tag deviceId=${SDK.getDeviceId()}")
            SDK.subscribeTag(tag, it)
        }
    }

    override fun unsubscribeTag(
        tag: String,
        callback: (Result<String>) -> Unit,
    ) {
        invokeAsync(callback, operation = "unsubscribeTag", context = mapOf("tag" to tag)) {
            SDK.unsubscribeTag(tag, it)
        }
    }

    override fun updatePersonalisationVariables(
        entries: List<PersonalisationEntry>,
        callback: (Result<String>) -> Unit,
    ) {
        val schema = entries.associate { it.name to it.value }
        invokeAsync(
            callback,
            operation = "updatePersonalisationVariables",
            context = mapOf("keys" to entries.map { it.name }.joinToString(",")),
        ) {
            SDK.updatePersonalisationVariables(schema, it)
        }
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
        invokeAsync(
            callback,
            operation = "showInAppNotification",
            context = mapOf("customIdentifier" to customIdentifier),
        ) {
            SDK.showInAppNotification(customIdentifier, it)
        }
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
            callback(Result.failure(error.toFlutterError(operation = "requestAuthorisationPrompts")))
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
        operation: String,
        context: Map<String, String> = emptyMap(),
        call: (SDKResponse<String>) -> Unit,
    ) {
        try {
            requireInitialized()
            call(
                object : SDKResponse<String> {
                    override fun onSuccess(result: String) {
                        Log.d(TAG, "$operation success result=$result context=$context")
                        callback(Result.success(result))
                    }

                    override fun onError(throwable: Throwable) {
                        val flutterError =
                            throwable.toFlutterError(operation = operation, context = context)
                        Log.e(
                            TAG,
                            "$operation failed code=${flutterError.code} message=${flutterError.message} details=${flutterError.details}",
                            throwable,
                        )
                        callback(Result.failure(flutterError))
                    }
                },
            )
        } catch (error: Throwable) {
            val flutterError = error.toFlutterError(operation = operation, context = context)
            Log.e(
                TAG,
                "$operation threw code=${flutterError.code} message=${flutterError.message}",
                error,
            )
            callback(Result.failure(flutterError))
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

    companion object {
        private const val TAG = "NotiveraFlutterPlugin"
    }
}

private fun Throwable.toFlutterError(
    operation: String,
    context: Map<String, String> = emptyMap(),
): FlutterError {
    if (this is FlutterError) {
        return this
    }

    val details =
        mutableMapOf<String, Any?>(
            "operation" to operation,
            "exceptionType" to (this::class.java.name),
            "deviceId" to runCatching { SDK.getDeviceId() }.getOrNull(),
        )
    details.putAll(context)

    // Retrofit is transitive via the native SDK AAR and is not a compile dependency of
    // this Flutter plugin, so detect HttpException by name / reflection.
    val httpDetails = extractHttpDetails(this)
    if (httpDetails != null) {
        details.putAll(httpDetails)
        val code = httpDetails["httpCode"] as? Int
        val requestUrl = httpDetails["requestUrl"] as? String
        val responseBody = httpDetails["responseBody"] as? String
        return FlutterError(
            if (code != null) "http-$code" else "http-error",
            buildString {
                append("HTTP ")
                append(code ?: "error")
                append(" during ")
                append(operation)
                if (!requestUrl.isNullOrBlank()) {
                    append(" (")
                    append(requestUrl)
                    append(")")
                }
                when {
                    !responseBody.isNullOrBlank() -> {
                        append(": ")
                        append(responseBody.take(500))
                    }
                    !message.isNullOrBlank() -> {
                        append(": ")
                        append(message)
                    }
                }
            },
            details,
        )
    }

    return when (this) {
        is UnknownHostException ->
            FlutterError(
                "network-unreachable",
                "Network unreachable during $operation: ${message ?: "unknown host"}",
                details,
            )
        is SocketTimeoutException ->
            FlutterError(
                "network-timeout",
                "Network timeout during $operation: ${message ?: "timed out"}",
                details,
            )
        is IOException ->
            FlutterError(
                "network-error",
                "Network error during $operation: ${message ?: javaClass.simpleName}",
                details,
            )
        else ->
            FlutterError(
                "sdk-error",
                message?.takeIf { it.isNotBlank() }
                    ?: "$operation failed with ${javaClass.simpleName}",
                details,
            )
    }
}

private fun extractHttpDetails(error: Throwable): Map<String, Any?>? {
    val className = error.javaClass.name
    val looksLikeHttp =
        className == "retrofit2.HttpException" ||
            className.endsWith(".HttpException") ||
            (error.message?.contains("HTTP ") == true)

    if (!looksLikeHttp) {
        return null
    }

    val reflectedCode =
        runCatching {
            error.javaClass.methods
                .firstOrNull { it.name == "code" && it.parameterTypes.isEmpty() }
                ?.invoke(error) as? Int
        }.getOrNull()

    val messageCode =
        run {
            val matcher = HTTP_CODE_PATTERN.matcher(error.message ?: "")
            if (matcher.find()) matcher.group(1).toIntOrNull() else null
        }

    val code = reflectedCode ?: messageCode

    val response =
        runCatching {
            error.javaClass.methods
                .firstOrNull { it.name == "response" && it.parameterTypes.isEmpty() }
                ?.invoke(error)
        }.getOrNull()

    val requestUrl =
        runCatching {
            val raw =
                response?.javaClass?.methods
                    ?.firstOrNull { it.name == "raw" && it.parameterTypes.isEmpty() }
                    ?.invoke(response)
            val request =
                raw?.javaClass?.methods
                    ?.firstOrNull { it.name == "request" && it.parameterTypes.isEmpty() }
                    ?.invoke(raw)
            val url =
                request?.javaClass?.methods
                    ?.firstOrNull { it.name == "url" && it.parameterTypes.isEmpty() }
                    ?.invoke(request)
            url?.toString()
        }.getOrNull()

    val responseBody =
        runCatching {
            val errorBody =
                response?.javaClass?.methods
                    ?.firstOrNull { it.name == "errorBody" && it.parameterTypes.isEmpty() }
                    ?.invoke(response)
            errorBody?.javaClass?.methods
                ?.firstOrNull { it.name == "string" && it.parameterTypes.isEmpty() }
                ?.invoke(errorBody) as? String
        }.getOrNull()
            ?.takeIf { it.isNotBlank() }

    return mapOf(
        "httpCode" to code,
        "httpMessage" to error.message,
        "requestUrl" to requestUrl,
        "responseBody" to responseBody,
    )
}

private val HTTP_CODE_PATTERN: Pattern = Pattern.compile("""HTTP\s+(\d{3})""")


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

/**
 * Maps Flutter [NotiveraPushTheme] resource **names** to Android `@DrawableRes` /
 * `@ColorRes` IDs for the native SDK. Missing names fall back to SDK defaults.
 */
private fun NotiveraConfig.toPushTheme(context: Context): SdkNotiveraPushTheme {
    val defaults = SdkNotiveraPushTheme()
    val theme = pushTheme ?: return defaults
    return SdkNotiveraPushTheme(
        smallIconRes =
            context.resolveDrawableOrMipmap(theme.smallIcon)
                ?: defaults.smallIconRes.also {
                    if (!theme.smallIcon.isNullOrBlank()) {
                        Log.w("NotiveraFlutterPlugin", "pushTheme.smallIcon '${theme.smallIcon}' not found; using SDK default")
                    }
                },
        largeIconRes =
            context.resolveDrawableOrMipmap(theme.largeIcon)
                ?: defaults.largeIconRes.also {
                    if (!theme.largeIcon.isNullOrBlank()) {
                        Log.w("NotiveraFlutterPlugin", "pushTheme.largeIcon '${theme.largeIcon}' not found; using SDK default")
                    }
                },
        color =
            context.resolveColorRes(theme.color)
                ?: defaults.color.also {
                    if (!theme.color.isNullOrBlank()) {
                        Log.w("NotiveraFlutterPlugin", "pushTheme.color '${theme.color}' not found; using SDK default")
                    }
                },
    )
}

private fun Context.resolveDrawableOrMipmap(name: String?): Int? {
    if (name.isNullOrBlank()) {
        return null
    }
    val drawable = resources.getIdentifier(name, "drawable", packageName)
    if (drawable != 0) {
        return drawable
    }
    val mipmap = resources.getIdentifier(name, "mipmap", packageName)
    return mipmap.takeIf { it != 0 }
}

private fun Context.resolveColorRes(name: String?): Int? {
    if (name.isNullOrBlank()) {
        return null
    }
    val color = resources.getIdentifier(name, "color", packageName)
    return color.takeIf { it != 0 }
}

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
