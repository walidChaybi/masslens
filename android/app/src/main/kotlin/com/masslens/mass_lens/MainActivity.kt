package com.masslens.mass_lens

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingArResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AR_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "startArMeasurement") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (pendingArResult != null) {
                result.error("busy", "An AR measurement is already open.", null)
                return@setMethodCallHandler
            }
            pendingArResult = result
            startActivityForResult(
                Intent(this, ArMeasureActivity::class.java),
                AR_REQUEST_CODE,
            )
        }
    }

    @Deprecated("Deprecated in Android SDK, retained for Flutter activity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != AR_REQUEST_CODE) return
        val result = pendingArResult ?: return
        pendingArResult = null

        val status = data?.getStringExtra(ArMeasureActivity.EXTRA_STATUS)
            ?: if (resultCode == Activity.RESULT_OK) "completed" else "cancelled"
        if (resultCode != Activity.RESULT_OK || status != "completed" || data == null) {
            result.success(mapOf("status" to status))
            return
        }

        val imagePath = data.getStringExtra(ArMeasureActivity.EXTRA_IMAGE_PATH)
        if (imagePath == null) {
            result.success(mapOf("status" to "fallback"))
            return
        }
        val depthMm = if (data.hasExtra(ArMeasureActivity.EXTRA_DEPTH_MM)) {
            data.getDoubleExtra(
                ArMeasureActivity.EXTRA_DEPTH_MM,
                0.0,
            )
        } else {
            null
        }
        result.success(
            encodeArMeasurementResult(
                imagePath = imagePath,
                widthMm = data.getDoubleExtra(ArMeasureActivity.EXTRA_WIDTH_MM, 0.0),
                heightMm = data.getDoubleExtra(ArMeasureActivity.EXTRA_HEIGHT_MM, 0.0),
                depthMm = depthMm,
                method = data.getStringExtra(ArMeasureActivity.EXTRA_METHOD)
                    ?: "arcore_plane",
            ),
        )
    }

    companion object {
        private const val AR_CHANNEL = "com.masslens.mass_lens/ar_measure"
        private const val AR_REQUEST_CODE = 7314
    }
}
