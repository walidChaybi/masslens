package com.masslens.mass_lens

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import com.google.mlkit.vision.common.InputImage
import com.google.android.gms.common.moduleinstall.ModuleInstall
import com.google.android.gms.common.moduleinstall.ModuleInstallRequest
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val cutouts by lazy { SubjectCutoutProcessor() }
    private val imageWorker = Executors.newSingleThreadExecutor()
    private val scanPrepareWorker = Executors.newSingleThreadExecutor()
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Warm the on-device segmentation module after launch so Play services
        // work does not compete with the first frame (slow cold starts).
        Handler(Looper.getMainLooper()).postDelayed({
            if (isFinishing || isDestroyed) return@postDelayed
            ModuleInstall.getClient(this).installModules(
                ModuleInstallRequest.newBuilder().addApi(cutouts.segmenter).build()
            ).addOnFailureListener { /* Normal scanning remains available. */ }
        }, 4000)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.masslens.mass_lens/reminders")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(MealReminders.canPostNotifications(this))
                    "requestPermission" -> requestNotificationPermission(result)
                    "enable" -> {
                        MealReminders.configure(
                            this,
                            call.argument<Int>("hour") ?: 12,
                            call.argument<Int>("minute") ?: 30,
                            call.argument<String>("title") ?: "",
                            call.argument<String>("body") ?: "",
                            call.argument<String>("channelName") ?: "",
                        )
                        result.success(MealReminders.canPostNotifications(this))
                    }
                    "disable" -> {
                        MealReminders.disable(this)
                        result.success(null)
                    }
                    "mealLogged" -> {
                        val at = call.argument<Number>("atMillis")?.toLong()
                            ?: System.currentTimeMillis()
                        MealReminders.noteMealLogged(this, at)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.masslens.mass_lens/scan_image")
            .setMethodCallHandler { call, result ->
                val path = call.argument<String>("path")
                if (call.method != "prepare" || path == null) {
                    result.notImplemented()
                } else {
                    // Heavy decode/resize/encode stays off the main thread and out of Dart.
                    scanPrepareWorker.execute {
                        try {
                            val prepared = ScanImagePreparer.prepare(path, cacheDir).toMap()
                            runOnUiThread { result.success(prepared) }
                        } catch (error: ScanImagePreparer.PrepareException) {
                            runOnUiThread { result.error(error.code, error.message, null) }
                        } catch (error: Throwable) {
                            runOnUiThread { result.error("corrupt", error.message, null) }
                        }
                    }
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.masslens.mass_lens/subject_cutout")
            .setMethodCallHandler { call, result ->
                val path = call.argument<String>("path")
                if (call.method != "extract" || path == null) {
                    result.notImplemented()
                } else {
                    imageWorker.execute {
                        try {
                            val bitmap = if (Build.VERSION.SDK_INT >= 28) {
                                ImageDecoder.decodeBitmap(ImageDecoder.createSource(File(path))) { decoder, info, _ ->
                                    decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
                                    decoder.setTargetSampleSize((maxOf(info.size.width, info.size.height) / 1024).coerceAtLeast(1))
                                }
                            } else BitmapFactory.decodeFile(path)
                            if (bitmap == null) {
                                runOnUiThread { result.success(null) }
                            } else cutouts.process(InputImage.fromBitmap(bitmap, 0)) { foreground ->
                                if (foreground == null) result.success(null)
                                else imageWorker.execute {
                                    try {
                                        val file = File.createTempFile("subject_", ".png", cacheDir)
                                        file.outputStream().use { foreground.compress(Bitmap.CompressFormat.PNG, 100, it) }
                                        runOnUiThread { result.success(file.absolutePath) }
                                    } catch (_: Exception) { runOnUiThread { result.success(null) } }
                                }
                            }
                        } catch (_: Exception) { runOnUiThread { result.success(null) } }
                    }
                }
            }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(MealReminders.canPostNotifications(this))
            return
        }
        pendingPermissionResult?.success(false)
        pendingPermissionResult = result
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != NOTIFICATION_PERMISSION_REQUEST) return
        val result = pendingPermissionResult ?: return
        pendingPermissionResult = null
        result.success(MealReminders.canPostNotifications(this))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Draw behind system bars; Flutter SafeArea / MediaQuery handle insets.
        WindowCompat.setDecorFitsSystemWindows(window, false)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Avoid Samsung's translucent 3-button contrast scrim stealing taps.
            window.isNavigationBarContrastEnforced = false
        }
        super.onCreate(savedInstanceState)
    }

    companion object {
        private const val NOTIFICATION_PERMISSION_REQUEST = 7301
    }
}
