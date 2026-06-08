package com.viti.gradebook_mobile

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.job.JobInfo
import android.app.job.JobScheduler
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.SystemClock
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class OfflineSyncReceiver : BroadcastReceiver() {

    companion object {
        private const val SYNC_ACTION = "com.viti.gradebook.OFFLINE_SYNC_ALARM"
        private const val ALARM_REQUEST_CODE = 777
        private const val JOB_ID = 778
        internal const val FLUTTER_PREFS = "FlutterSharedPreferences"
        internal const val QUEUE_KEY = "flutter.offline_queue"
        private const val SECURE_PREFS = "FlutterSecureStorage"
        private const val BASE_URL = "https://gradebook.viti.edu.ua/api"
        private const val CF_ID = "3041217c4cb0104098b18aaa97a5b476.access"
        private const val CF_SECRET = "fcd30b8531a9a0c1099e04ed8a3d0b3bc00be9fed51066d49e414d5afc749aa9"

        fun schedule(context: Context) {
            val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val queue = prefs.getString(QUEUE_KEY, null)
            if (queue.isNullOrEmpty() || queue == "[]") return

            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pi = makePendingIntent(context)
            val triggerAt = SystemClock.elapsedRealtime() + 60_000L
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    am.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pi)
                } else {
                    am.setExact(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pi)
                }
            } catch (_: SecurityException) {
                am.set(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pi)
            }
        }

        fun cancel(context: Context) {
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            am.cancel(makePendingIntent(context))
        }

        // JobScheduler approach: fires immediately when any network returns —
        // works even when app is killed, survives reboots (setPersisted = true),
        // and is respected by OEM power managers that throttle AlarmManager/WorkManager.
        fun scheduleJob(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return
            val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val queue = prefs.getString(QUEUE_KEY, null)
            if (queue.isNullOrEmpty() || queue == "[]") return

            val js = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
            val job = JobInfo.Builder(JOB_ID, ComponentName(context, OfflineSyncJobService::class.java))
                .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)
                .setPersisted(true)
                .build()
            js.schedule(job)
        }

        fun cancelJob(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return
            (context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler).cancel(JOB_ID)
        }

        private fun makePendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, OfflineSyncReceiver::class.java).apply {
                action = SYNC_ACTION
            }
            return PendingIntent.getBroadcast(
                context, ALARM_REQUEST_CODE, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        // Returns true if all ops were sent (queue now empty), false if some remain.
        fun performSync(context: Context): Boolean {
            val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val queueJson = prefs.getString(QUEUE_KEY, null) ?: return true
            if (queueJson.isEmpty() || queueJson == "[]") return true

            val token = getToken(context) ?: run {
                schedule(context)
                return false
            }

            val ops = try {
                JSONArray(queueJson)
            } catch (_: Exception) {
                prefs.edit().remove(QUEUE_KEY).apply()
                cancel(context)
                cancelJob(context)
                return true
            }

            val remaining = JSONArray()
            for (i in 0 until ops.length()) {
                val op = ops.optJSONObject(i) ?: continue
                if (!trySendOp(op, token)) remaining.put(op)
            }

            return if (remaining.length() == 0) {
                prefs.edit().remove(QUEUE_KEY).apply()
                cancel(context)
                cancelJob(context)
                true
            } else {
                prefs.edit().putString(QUEUE_KEY, remaining.toString()).apply()
                schedule(context)
                false
            }
        }

        fun getToken(context: Context): String? = try {
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
            EncryptedSharedPreferences.create(
                context, SECURE_PREFS, masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            ).getString("access_token", null)
        } catch (_: Exception) { null }

        fun trySendOp(op: JSONObject, token: String): Boolean = try {
            val method = op.getString("method")
            val path = op.getString("path")
            val bodyJson: String? = when {
                op.isNull("data") || method == "DELETE" -> null
                op.optJSONObject("data") != null -> op.getJSONObject("data").toString()
                op.optJSONArray("data") != null -> op.getJSONArray("data").toString()
                else -> null
            }

            val conn = URL(BASE_URL + path).openConnection() as HttpURLConnection
            conn.requestMethod = method
            conn.connectTimeout = 8_000
            conn.readTimeout = 8_000
            conn.setRequestProperty("Authorization", "Bearer $token")
            conn.setRequestProperty("CF-Access-Client-Id", CF_ID)
            conn.setRequestProperty("CF-Access-Client-Secret", CF_SECRET)
            conn.setRequestProperty("Content-Type", "application/json")
            conn.setRequestProperty("Accept", "application/json")

            if (bodyJson != null) {
                conn.doOutput = true
                conn.outputStream.use { it.write(bodyJson.toByteArray(Charsets.UTF_8)) }
            }

            val code = conn.responseCode
            conn.disconnect()
            code in 200..299 || code == 409
        } catch (_: Exception) { false }
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action != Intent.ACTION_BOOT_COMPLETED && action != SYNC_ACTION) return

        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val queue = prefs.getString(QUEUE_KEY, null)
        if (queue.isNullOrEmpty() || queue == "[]") return

        if (!isOnline(context)) {
            // No network — keep polling via alarm AND ensure job is scheduled
            // so it fires the moment network returns (without waiting for next alarm tick)
            schedule(context)
            scheduleJob(context)
            return
        }

        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                performSync(context)
            } finally {
                pendingResult.finish()
            }
        }
    }

    private fun isOnline(context: Context): Boolean {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            cm.activeNetwork?.let { cm.getNetworkCapabilities(it) }
                ?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
        } else {
            @Suppress("DEPRECATION")
            cm.activeNetworkInfo?.isConnected == true
        }
    }
}
