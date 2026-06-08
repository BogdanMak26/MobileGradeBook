package com.viti.gradebook_mobile

import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val CHANNEL       = "com.viti.gradebook/settings"
        private const val NETWORK_EVENT = "com.viti.gradebook/network"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var networkEventSink: EventChannel.EventSink? = null

    // Fires as soon as a network with INTERNET capability becomes available —
    // even if Flutter's Dart isolate was suspended in the background.
    private val networkCallback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            mainHandler.post { networkEventSink?.success(true) }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openSecuritySettings" -> {
                        startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS))
                        result.success(null)
                    }
                    "hasBiometricHardware" -> {
                        val bm = BiometricManager.from(this)
                        val status = bm.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK)
                        result.success(status != BiometricManager.BIOMETRIC_ERROR_NO_HARDWARE)
                    }
                    "authenticateWithDeviceCredential" -> {
                        val reason = call.argument<String>("reason") ?: ""
                        authenticateCredential(reason, result)
                    }
                    "scheduleOfflineSyncAlarm" -> {
                        OfflineSyncReceiver.schedule(this)
                        OfflineSyncReceiver.scheduleJob(this)
                        result.success(null)
                    }
                    "cancelOfflineSyncAlarm" -> {
                        OfflineSyncReceiver.cancel(this)
                        OfflineSyncReceiver.cancelJob(this)
                        result.success(null)
                    }
                    "checkBatteryOptimization" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "requestIgnoreBatteryOptimization" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            intent.data = Uri.parse("package:$packageName")
                            startActivity(intent)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_EVENT)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    networkEventSink = events
                    val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                    val request = NetworkRequest.Builder()
                        .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
                        .build()
                    cm.registerNetworkCallback(request, networkCallback)
                }
                override fun onCancel(arguments: Any?) {
                    networkEventSink = null
                    try {
                        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                        cm.unregisterNetworkCallback(networkCallback)
                    } catch (_: Exception) {}
                }
            })
    }

    private fun authenticateCredential(reason: String, methodResult: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            // Android 10 and below — DEVICE_CREDENTIAL-only BiometricPrompt not supported.
            // Report back so Flutter can fall back to local_auth.
            methodResult.success("notImplemented")
            return
        }

        val executor = ContextCompat.getMainExecutor(this)
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                methodResult.success("success")
            }
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                val r = when (errorCode) {
                    BiometricPrompt.ERROR_USER_CANCELED,
                    BiometricPrompt.ERROR_NEGATIVE_BUTTON  -> "cancelled"
                    BiometricPrompt.ERROR_LOCKOUT,
                    BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> "lockedOut"
                    BiometricPrompt.ERROR_NO_DEVICE_CREDENTIAL -> "notEnrolled"
                    else -> "failed"
                }
                methodResult.success(r)
            }
            // onAuthenticationFailed fires on each wrong attempt — don't resolve yet
            override fun onAuthenticationFailed() {}
        }

        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("GradeBook")
            .setSubtitle(reason)
            .setAllowedAuthenticators(BiometricManager.Authenticators.DEVICE_CREDENTIAL)
            .build()

        BiometricPrompt(this, executor, callback).authenticate(promptInfo)
    }
}
