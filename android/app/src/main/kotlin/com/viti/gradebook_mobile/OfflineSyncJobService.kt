package com.viti.gradebook_mobile

import android.app.job.JobParameters
import android.app.job.JobService
import android.os.Build
import androidx.annotation.RequiresApi
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

// Triggered by JobScheduler the moment the network constraint is satisfied —
// i.e. as soon as any network interface becomes available, even when app is killed.
// setPersisted=true in scheduleJob() means this job is re-registered after reboot.
@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class OfflineSyncJobService : JobService() {

    override fun onStartJob(params: JobParameters): Boolean {
        val ctx = applicationContext
        val prefs = ctx.getSharedPreferences(OfflineSyncReceiver.FLUTTER_PREFS, MODE_PRIVATE)
        val queue = prefs.getString(OfflineSyncReceiver.QUEUE_KEY, null)
        if (queue.isNullOrEmpty() || queue == "[]") return false

        CoroutineScope(Dispatchers.IO).launch {
            try {
                OfflineSyncReceiver.performSync(ctx)
            } finally {
                jobFinished(params, false)
            }
        }
        return true // async — don't call jobFinished yet
    }

    // Return true → JobScheduler reschedules this job automatically if it's killed mid-run
    override fun onStopJob(params: JobParameters): Boolean = true
}
