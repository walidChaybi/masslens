package com.masslens.mass_lens

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.ColorStateList
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.DashPathEffect
import android.graphics.ImageFormat
import android.graphics.Matrix as GraphicsMatrix
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.YuvImage
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.Image
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.opengl.Matrix
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.Surface
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.view.WindowInsets
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import com.google.ar.core.Anchor
import com.google.ar.core.ArCoreApk
import com.google.ar.core.Config
import com.google.ar.core.Coordinates2d
import com.google.ar.core.DepthPoint
import com.google.ar.core.Frame
import com.google.ar.core.HitResult
import com.google.ar.core.Plane
import com.google.ar.core.Point
import com.google.ar.core.Pose
import com.google.ar.core.Session
import com.google.ar.core.TrackingState
import com.google.ar.core.exceptions.CameraNotAvailableException
import com.google.ar.core.exceptions.NotYetAvailableException
import com.google.ar.core.exceptions.UnavailableException
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.util.concurrent.atomic.AtomicBoolean

class ArMeasureActivity : Activity(), GLSurfaceView.Renderer {
    private lateinit var surfaceView: GLSurfaceView
    private lateinit var overlayView: MeasurementOverlayView
    private lateinit var instructionView: TextView
    private lateinit var axisView: TextView
    private lateinit var addButton: TextView
    private lateinit var doneButton: Button
    private var session: Session? = null
    private var installRequested = false
    private var depthSupported = false
    private var viewportWidth = 1
    private var viewportHeight = 1
    private var cameraTextureId = 0
    private var backgroundProgram = 0
    private var positionAttribute = 0
    private var textureAttribute = 0
    private var textureUniform = 0
    private val addRequested = AtomicBoolean(false)
    private val captureRequested = AtomicBoolean(false)
    private val trackingFallbackRequested = AtomicBoolean(false)
    private val measurementLines = mutableListOf<MeasurementLine>()
    private val measurementState = ArMeasurementState()
    private var pendingPoint: PlacedPoint? = null
    private var lastUiState = ""
    private var messageText: String? = null
    private var messageUntil = 0L
    private var capturing = false
    private var hasTracked = false
    private var trackingDeadline = Long.MAX_VALUE
    private val centerHitSamples = ArrayDeque<CenterHitSample>()
    private var lastCenterHitSampleAt = 0L

    private val quadCoordinates = floatBufferOf(
        -1f, -1f,
        1f, -1f,
        -1f, 1f,
        1f, 1f,
    )
    private val textureCoordinates = floatBufferOf(
        0f, 0f,
        1f, 0f,
        0f, 1f,
        1f, 1f,
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.BLACK
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility =
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        }
        buildInterface()
    }

    private fun buildInterface() {
        val root = FrameLayout(this).apply { setBackgroundColor(Color.BLACK) }
        surfaceView = GLSurfaceView(this).apply {
            setEGLContextClientVersion(2)
            preserveEGLContextOnPause = true
            setRenderer(this@ArMeasureActivity)
            renderMode = GLSurfaceView.RENDERMODE_CONTINUOUSLY
        }
        overlayView = MeasurementOverlayView(this)
        root.addView(
            surfaceView,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        root.addView(
            overlayView,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )

        val topBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12), dp(8), dp(12), dp(8))
        }
        val closeButton = roundImageButton(
            android.R.drawable.ic_menu_close_clear_cancel,
            "Close measurement",
        ) { finishWithStatus("cancelled") }
        axisView = TextView(this).apply {
            setTextColor(Color.WHITE)
            textSize = 12f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            background = roundedBackground(Color.argb(145, 0, 0, 0), dp(8).toFloat())
            setPadding(dp(12), dp(8), dp(12), dp(8))
        }
        topBar.addView(closeButton, LinearLayout.LayoutParams(dp(48), dp(48)))
        topBar.addView(
            axisView,
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginStart = dp(10)
                marginEnd = dp(58)
            },
        )
        val topBarLayout = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.TOP,
        ).apply { topMargin = dp(8) }
        root.addView(topBar, topBarLayout)

        val bottomPanel = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(14), dp(10), dp(14), dp(12))
            background = roundedBackground(Color.argb(175, 8, 13, 20), dp(8).toFloat())
        }
        instructionView = TextView(this).apply {
            setTextColor(Color.WHITE)
            textSize = 16f
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        bottomPanel.addView(
            instructionView,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ),
        )
        val controls = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dp(8), 0, 0)
        }
        val undo = roundImageButton(android.R.drawable.ic_menu_revert, "Undo point") {
            surfaceView.queueEvent { undoOnGlThread() }
        }
        addButton = TextView(this).apply {
            text = "+"
            textSize = 34f
            gravity = Gravity.CENTER
            setTextColor(Color.rgb(19, 34, 56))
            contentDescription = "Add measurement point"
            isClickable = true
            isFocusable = true
            background = roundedBackground(LIME, dp(32).toFloat())
            setOnClickListener { addRequested.set(true) }
        }
        val reset = roundImageButton(android.R.drawable.ic_menu_delete, "Reset points") {
            surfaceView.queueEvent { resetOnGlThread() }
        }
        doneButton = Button(this).apply {
            text = "Done"
            textSize = 15f
            isAllCaps = false
            isEnabled = false
            setTextColor(Color.rgb(19, 34, 56))
            backgroundTintList = ColorStateList.valueOf(Color.WHITE)
            setOnClickListener {
                if (isEnabled && !capturing) {
                    capturing = true
                    text = "Saving"
                    captureRequested.set(true)
                }
            }
        }
        controls.addView(undo, LinearLayout.LayoutParams(dp(44), dp(44)))
        controls.addView(
            addButton,
            LinearLayout.LayoutParams(dp(64), dp(64)).apply {
                marginStart = dp(12)
                marginEnd = dp(12)
            },
        )
        controls.addView(reset, LinearLayout.LayoutParams(dp(44), dp(44)))
        controls.addView(
            doneButton,
            LinearLayout.LayoutParams(0, dp(48), 1f).apply {
                marginStart = dp(14)
            },
        )
        bottomPanel.addView(controls)
        val bottomPanelLayout = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.BOTTOM,
        ).apply {
            leftMargin = dp(12)
            rightMargin = dp(12)
            bottomMargin = dp(12)
        }
        root.addView(bottomPanel, bottomPanelLayout)
        setContentView(root)
        applySystemBarInsets(root, topBarLayout, bottomPanelLayout)
        updateControls(false, false, false)
    }

    private fun applySystemBarInsets(
        root: View,
        topBarLayout: FrameLayout.LayoutParams,
        bottomPanelLayout: FrameLayout.LayoutParams,
    ) {
        root.setOnApplyWindowInsetsListener { _, insets ->
            val (topInset, bottomInset) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val systemBars = insets.getInsets(WindowInsets.Type.systemBars())
                systemBars.top to systemBars.bottom
            } else {
                @Suppress("DEPRECATION")
                (insets.systemWindowInsetTop to insets.systemWindowInsetBottom)
            }
            topBarLayout.topMargin = topInset + dp(8)
            bottomPanelLayout.bottomMargin = bottomInset + dp(12)
            root.requestLayout()
            insets
        }
        root.requestApplyInsets()
    }

    override fun onResume() {
        super.onResume()
        if (checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.CAMERA), CAMERA_PERMISSION_REQUEST)
            return
        }
        resumeArSession()
    }

    private fun resumeArSession() {
        if (session == null) {
            try {
                when (ArCoreApk.getInstance().requestInstall(this, !installRequested)) {
                    ArCoreApk.InstallStatus.INSTALL_REQUESTED -> {
                        installRequested = true
                        return
                    }
                    ArCoreApk.InstallStatus.INSTALLED -> Unit
                }
                session = Session(this).also { activeSession ->
                    val config = activeSession.config
                    depthSupported = activeSession.isDepthModeSupported(
                        Config.DepthMode.AUTOMATIC,
                    )
                    if (depthSupported) config.depthMode = Config.DepthMode.AUTOMATIC
                    activeSession.configure(config)
                }
            } catch (_: UnavailableException) {
                finishWithStatus("fallback")
                return
            } catch (_: SecurityException) {
                finishWithStatus("cancelled")
                return
            }
        }
        try {
            session?.resume()
            hasTracked = false
            trackingFallbackRequested.set(false)
            trackingDeadline = SystemClock.uptimeMillis() + TRACKING_TIMEOUT_MS
            session?.setDisplayGeometry(
                windowManager.defaultDisplay.rotation,
                viewportWidth,
                viewportHeight,
            )
            surfaceView.onResume()
        } catch (_: CameraNotAvailableException) {
            session = null
            finishWithStatus("fallback")
        }
    }

    override fun onPause() {
        surfaceView.onPause()
        session?.pause()
        super.onPause()
    }

    override fun onDestroy() {
        measurementLines.forEach { it.detach() }
        pendingPoint?.anchor?.detach()
        session?.close()
        session = null
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != CAMERA_PERMISSION_REQUEST) return
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            resumeArSession()
        } else {
            finishWithStatus("cancelled")
        }
    }

    override fun onSurfaceCreated(gl: javax.microedition.khronos.opengles.GL10?, config: javax.microedition.khronos.egl.EGLConfig?) {
        GLES20.glClearColor(0f, 0f, 0f, 1f)
        cameraTextureId = createCameraTexture()
        backgroundProgram = createProgram(VERTEX_SHADER, FRAGMENT_SHADER)
        positionAttribute = GLES20.glGetAttribLocation(backgroundProgram, "a_Position")
        textureAttribute = GLES20.glGetAttribLocation(backgroundProgram, "a_TexCoord")
        textureUniform = GLES20.glGetUniformLocation(backgroundProgram, "u_Texture")
    }

    override fun onSurfaceChanged(gl: javax.microedition.khronos.opengles.GL10?, width: Int, height: Int) {
        viewportWidth = width.coerceAtLeast(1)
        viewportHeight = height.coerceAtLeast(1)
        GLES20.glViewport(0, 0, viewportWidth, viewportHeight)
        session?.setDisplayGeometry(
            windowManager.defaultDisplay.rotation,
            viewportWidth,
            viewportHeight,
        )
    }

    override fun onDrawFrame(gl: javax.microedition.khronos.opengles.GL10?) {
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)
        val activeSession = session ?: return
        try {
            activeSession.setCameraTextureName(cameraTextureId)
            val frame = activeSession.update()
            if (frame.hasDisplayGeometryChanged()) {
                session?.setDisplayGeometry(
                    windowManager.defaultDisplay.rotation,
                    viewportWidth,
                    viewportHeight,
                )
                updateTextureCoordinates(frame)
            }
            drawCameraBackground()

            val tracking = frame.camera.trackingState == TrackingState.TRACKING
            if (tracking) hasTracked = true
            if (
                !tracking &&
                !hasTracked &&
                SystemClock.uptimeMillis() >= trackingDeadline &&
                trackingFallbackRequested.compareAndSet(false, true)
            ) {
                runOnUiThread { finishWithStatus("fallback") }
                return
            }
            val hit = if (tracking) bestCenterHit(frame) else null
            var stableHit = updateCenterHitSamples(hit)
            if (addRequested.getAndSet(false)) {
                if (stableHit == null) {
                    showTemporaryMessage("Hold steady before placing the point")
                } else {
                    placePoint(stableHit)
                    stableHit = null
                }
            }
            updateOverlay(frame, hit)
            updateControls(tracking, hit != null, stableHit != null)
            if (captureRequested.getAndSet(false)) captureFrame(frame)
        } catch (_: CameraNotAvailableException) {
            runOnUiThread { finishWithStatus("fallback") }
        }
    }

    private fun bestCenterHit(frame: Frame): HitResult? {
        val hits = frame.hitTest(viewportWidth / 2f, viewportHeight / 2f)
        fun valid(hit: HitResult): Boolean = when (val trackable = hit.trackable) {
            is DepthPoint -> true
            is Plane -> trackable.isPoseInPolygon(hit.hitPose)
            is Point -> true
            else -> false
        }
        return hits.firstOrNull { it.trackable is DepthPoint && valid(it) }
            ?: hits.firstOrNull { it.trackable is Plane && valid(it) }
            ?: hits.firstOrNull { it.trackable is Point && valid(it) }
    }

    private fun updateCenterHitSamples(hit: HitResult?): StableCenterHit? {
        if (hit == null) {
            clearCenterHitSamples()
            return null
        }
        val kind = when (hit.trackable) {
            is DepthPoint -> CenterHitKind.DEPTH
            is Plane -> CenterHitKind.PLANE
            else -> CenterHitKind.POINT
        }
        val previousKind = centerHitSamples.lastOrNull()?.kind
        if (previousKind != null && previousKind != kind) {
            clearCenterHitSamples()
        }
        val now = SystemClock.uptimeMillis()
        if (now - lastCenterHitSampleAt >= CENTER_HIT_SAMPLE_INTERVAL_MS) {
            centerHitSamples.addLast(
                CenterHitSample(
                    translation = hit.hitPose.translation.copyOf(),
                    kind = kind,
                    timestampMillis = now,
                ),
            )
            lastCenterHitSampleAt = now
        }
        while (
            centerHitSamples.isNotEmpty() &&
            (
                centerHitSamples.size > CENTER_HIT_SAMPLE_COUNT ||
                    now - centerHitSamples.first().timestampMillis > CENTER_HIT_MAX_AGE_MS
            )
        ) {
            centerHitSamples.removeFirst()
        }
        if (
            centerHitSamples.size < CENTER_HIT_SAMPLE_COUNT ||
            centerHitSamples.last().timestampMillis - centerHitSamples.first().timestampMillis <
            CENTER_HIT_MIN_DURATION_MS
        ) {
            return null
        }
        val translation = ArMeasurementMath.stableTranslation(
            centerHitSamples.map { it.translation },
            MAX_CENTER_HIT_SPREAD_MM,
        ) ?: return null
        if (
            ArMeasurementMath.distanceMillimeters(
                translation,
                hit.hitPose.translation,
            ) > MAX_CENTER_HIT_SPREAD_MM
        ) {
            return null
        }
        return StableCenterHit(
            pose = Pose.makeTranslation(translation[0], translation[1], translation[2]),
            fromDepth = kind == CenterHitKind.DEPTH,
        )
    }

    private fun clearCenterHitSamples() {
        centerHitSamples.clear()
        lastCenterHitSampleAt = 0L
    }

    private fun placePoint(hit: StableCenterHit) {
        if (measurementLines.size >= 3) return
        val activeSession = session ?: return
        val point = PlacedPoint(activeSession.createAnchor(hit.pose), hit.fromDepth)
        val first = pendingPoint
        if (first == null) {
            pendingPoint = point
            clearCenterHitSamples()
            runOnUiThread { addButton.performHapticFeedback(HapticFeedbackConstants.CONFIRM) }
            return
        }
        val axis = currentAxis()
        val firstTranslation = first.anchor.pose.translation
        val secondTranslation = point.anchor.pose.translation
        val millimeters = ArMeasurementMath.axisDistanceMillimeters(
            axis,
            firstTranslation,
            secondTranslation,
        )
        val alignment = ArMeasurementMath.alignmentRatio(
            axis,
            firstTranslation,
            secondTranslation,
        )
        if (alignment < MIN_AXIS_ALIGNMENT_RATIO) {
            point.anchor.detach()
            clearCenterHitSamples()
            showTemporaryMessage(
                if (axis == MeasureAxis.HEIGHT) {
                    "Measure height straight up and down"
                } else {
                    "Keep this measurement level"
                },
            )
            return
        }
        if (millimeters !in MIN_MM..MAX_MM) {
            point.anchor.detach()
            clearCenterHitSamples()
            showTemporaryMessage("Keep the measurement between 0.5 cm and 5 m")
            return
        }
        measurementLines += MeasurementLine(
            axis = measurementState.complete(millimeters),
            first = first,
            second = point,
        )
        pendingPoint = null
        clearCenterHitSamples()
        runOnUiThread { addButton.performHapticFeedback(HapticFeedbackConstants.CONFIRM) }
    }

    private fun undoOnGlThread() {
        val pending = pendingPoint
        if (pending != null) {
            pending.anchor.detach()
            pendingPoint = null
        } else if (measurementLines.isNotEmpty()) {
            measurementLines.removeLast().detach()
            measurementState.undo()
        }
        clearCenterHitSamples()
        lastUiState = ""
    }

    private fun resetOnGlThread() {
        measurementLines.forEach { it.detach() }
        measurementLines.clear()
        measurementState.reset()
        pendingPoint?.anchor?.detach()
        pendingPoint = null
        clearCenterHitSamples()
        lastUiState = ""
    }

    private fun currentAxis(): MeasureAxis = measurementState.currentAxis

    private fun updateControls(
        tracking: Boolean,
        hitValid: Boolean,
        hitStable: Boolean,
    ) {
        val axis = currentAxis()
        val hasFirst = pendingPoint != null
        val message = if (SystemClock.uptimeMillis() < messageUntil) messageText else null
        val uiState =
            "$tracking|$hitValid|$hitStable|$axis|$hasFirst|${measurementLines.size}|$message"
        if (uiState == lastUiState) return
        lastUiState = uiState
        runOnUiThread {
            val instruction = message ?: when {
                !tracking -> "Move your phone slowly"
                !hitValid -> "Aim at a visible surface"
                !hitStable -> "Hold steady"
                hasFirst && axis == MeasureAxis.HEIGHT -> "Place the top point"
                hasFirst -> "Place the other end"
                axis == MeasureAxis.WIDTH -> "Place one end of the length"
                axis == MeasureAxis.HEIGHT -> "Place the bottom point"
                else -> "Optional: place the front depth point"
            }
            instructionView.text = instruction
            val stepNumber = (measurementState.completedCount + 1).coerceAtMost(3)
            axisView.text = if (axis == MeasureAxis.DEPTH) {
                "DEPTH  ·  OPTIONAL"
            } else {
                "${axis.label.uppercase()}  ·  $stepNumber OF 2"
            }
            addButton.isEnabled =
                tracking && hitStable && !capturing && measurementLines.size < 3
            addButton.alpha = if (addButton.isEnabled) 1f else 0.45f
            doneButton.isEnabled = measurementState.canFinish && !capturing
            overlayView.setReticleValid(tracking && hitStable)
        }
    }

    private fun showTemporaryMessage(message: String) {
        messageText = message
        messageUntil = SystemClock.uptimeMillis() + 1800
        lastUiState = ""
    }

    private fun updateOverlay(frame: Frame, hit: HitResult?) {
        val camera = frame.camera
        if (camera.trackingState != TrackingState.TRACKING) {
            overlayView.updateLines(emptyList(), null)
            return
        }
        val view = FloatArray(16)
        val projection = FloatArray(16)
        val viewProjection = FloatArray(16)
        camera.getViewMatrix(view, 0)
        camera.getProjectionMatrix(projection, 0, 0.05f, 100f)
        Matrix.multiplyMM(viewProjection, 0, projection, 0, view, 0)

        val lines = measurementLines.mapNotNull { line ->
            val first = project(line.first.anchor.pose, viewProjection) ?: return@mapNotNull null
            val second = project(line.second.anchor.pose, viewProjection) ?: return@mapNotNull null
            OverlayLine(
                first,
                second,
                "${line.axis.label} ${formatDistance(line.currentMillimeters)}",
                false,
            )
        }
        val pending = pendingPoint?.let { point ->
            val first = project(point.anchor.pose, viewProjection)
            val second = hit?.hitPose?.let { project(it, viewProjection) }
            if (first != null && second != null) {
                val distance = ArMeasurementMath.axisDistanceMillimeters(
                    currentAxis(),
                    point.anchor.pose.translation,
                    hit.hitPose.translation,
                )
                OverlayLine(first, second, "${currentAxis().label} ${formatDistance(distance)}", true)
            } else {
                null
            }
        }
        overlayView.updateLines(lines, pending)
    }

    private fun project(pose: Pose, viewProjection: FloatArray): android.graphics.PointF? {
        val translation = pose.translation
        val clip = FloatArray(4)
        Matrix.multiplyMV(
            clip,
            0,
            viewProjection,
            0,
            floatArrayOf(translation[0], translation[1], translation[2], 1f),
            0,
        )
        if (clip[3] <= 0f) return null
        val normalizedX = clip[0] / clip[3]
        val normalizedY = clip[1] / clip[3]
        return android.graphics.PointF(
            (normalizedX + 1f) * 0.5f * viewportWidth,
            (1f - normalizedY) * 0.5f * viewportHeight,
        )
    }

    private fun captureFrame(frame: Frame) {
        val widthLine = measurementLines.firstOrNull { it.axis == MeasureAxis.WIDTH }
        val heightLine = measurementLines.firstOrNull { it.axis == MeasureAxis.HEIGHT }
        val depthLine = measurementLines.firstOrNull { it.axis == MeasureAxis.DEPTH }
        val width = widthLine?.currentMillimeters
        val height = heightLine?.currentMillimeters
        val depth = depthLine?.currentMillimeters
        val requiredLinesAreValid =
            widthLine != null &&
                heightLine != null &&
                width != null &&
                height != null &&
                width in MIN_MM..MAX_MM &&
                height in MIN_MM..MAX_MM &&
                widthLine.currentAlignment >= MIN_AXIS_ALIGNMENT_RATIO &&
                heightLine.currentAlignment >= MIN_AXIS_ALIGNMENT_RATIO
        val depthIsValid =
            depthLine == null ||
                (
                    depth != null &&
                        depth in MIN_MM..MAX_MM &&
                        depthLine.currentAlignment >= MIN_AXIS_ALIGNMENT_RATIO
                )
        if (!requiredLinesAreValid || !depthIsValid) {
            capturing = false
            showTemporaryMessage("A point moved. Undo that line and measure it again")
            runOnUiThread { doneButton.text = "Done" }
            return
        }
        try {
            frame.acquireCameraImage().use { image ->
                val jpeg = Yuv420Converter.toJpeg(image, cameraRotationDegrees())
                val file = File(cacheDir, "masslens-ar-${System.currentTimeMillis()}.jpg")
                FileOutputStream(file).use { it.write(jpeg) }
                val method = if (
                    depthSupported && measurementLines.all { it.usedOnlyDepthPoints }
                ) {
                    "arcore_depth"
                } else {
                    "arcore_plane"
                }
                runOnUiThread {
                    val data = Intent()
                        .putExtra(EXTRA_STATUS, "completed")
                        .putExtra(EXTRA_IMAGE_PATH, file.absolutePath)
                        .putExtra(EXTRA_WIDTH_MM, checkNotNull(width))
                        .putExtra(EXTRA_HEIGHT_MM, checkNotNull(height))
                        .putExtra(EXTRA_METHOD, method)
                    if (depth != null) data.putExtra(EXTRA_DEPTH_MM, depth)
                    setResult(RESULT_OK, data)
                    finish()
                }
            }
        } catch (_: NotYetAvailableException) {
            capturing = false
            showTemporaryMessage("Hold steady, then tap Done again")
            runOnUiThread { doneButton.text = "Done" }
        } catch (_: Exception) {
            capturing = false
            showTemporaryMessage("Could not save this frame. Try again")
            runOnUiThread { doneButton.text = "Done" }
        }
    }

    private fun cameraRotationDegrees(): Int {
        val activeSession = session ?: return 90
        val manager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val sensorOrientation = manager.getCameraCharacteristics(
            activeSession.cameraConfig.cameraId,
        ).get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 90
        val displayDegrees = when (windowManager.defaultDisplay.rotation) {
            Surface.ROTATION_90 -> 90
            Surface.ROTATION_180 -> 180
            Surface.ROTATION_270 -> 270
            else -> 0
        }
        return (sensorOrientation - displayDegrees + 360) % 360
    }

    private fun updateTextureCoordinates(frame: Frame) {
        quadCoordinates.position(0)
        textureCoordinates.position(0)
        frame.transformCoordinates2d(
            Coordinates2d.OPENGL_NORMALIZED_DEVICE_COORDINATES,
            quadCoordinates,
            Coordinates2d.TEXTURE_NORMALIZED,
            textureCoordinates,
        )
    }

    private fun drawCameraBackground() {
        GLES20.glDisable(GLES20.GL_DEPTH_TEST)
        GLES20.glUseProgram(backgroundProgram)
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, cameraTextureId)
        GLES20.glUniform1i(textureUniform, 0)
        quadCoordinates.position(0)
        GLES20.glEnableVertexAttribArray(positionAttribute)
        GLES20.glVertexAttribPointer(
            positionAttribute,
            2,
            GLES20.GL_FLOAT,
            false,
            0,
            quadCoordinates,
        )
        textureCoordinates.position(0)
        GLES20.glEnableVertexAttribArray(textureAttribute)
        GLES20.glVertexAttribPointer(
            textureAttribute,
            2,
            GLES20.GL_FLOAT,
            false,
            0,
            textureCoordinates,
        )
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GLES20.glDisableVertexAttribArray(positionAttribute)
        GLES20.glDisableVertexAttribArray(textureAttribute)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 0)
    }

    private fun createCameraTexture(): Int {
        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, textures[0])
        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_MIN_FILTER,
            GLES20.GL_LINEAR,
        )
        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_MAG_FILTER,
            GLES20.GL_LINEAR,
        )
        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_WRAP_S,
            GLES20.GL_CLAMP_TO_EDGE,
        )
        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_WRAP_T,
            GLES20.GL_CLAMP_TO_EDGE,
        )
        return textures[0]
    }

    private fun createProgram(vertex: String, fragment: String): Int {
        val program = GLES20.glCreateProgram()
        GLES20.glAttachShader(program, compileShader(GLES20.GL_VERTEX_SHADER, vertex))
        GLES20.glAttachShader(program, compileShader(GLES20.GL_FRAGMENT_SHADER, fragment))
        GLES20.glLinkProgram(program)
        val linked = IntArray(1)
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linked, 0)
        check(linked[0] == GLES20.GL_TRUE) { GLES20.glGetProgramInfoLog(program) }
        return program
    }

    private fun compileShader(type: Int, source: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, source)
        GLES20.glCompileShader(shader)
        val compiled = IntArray(1)
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0)
        check(compiled[0] == GLES20.GL_TRUE) { GLES20.glGetShaderInfoLog(shader) }
        return shader
    }

    private fun finishWithStatus(status: String) {
        setResult(RESULT_CANCELED, Intent().putExtra(EXTRA_STATUS, status))
        finish()
    }

    private fun roundImageButton(icon: Int, description: String, action: () -> Unit): ImageButton {
        return ImageButton(this).apply {
            setImageResource(icon)
            imageTintList = ColorStateList.valueOf(Color.WHITE)
            contentDescription = description
            background = roundedBackground(Color.argb(145, 0, 0, 0), dp(24).toFloat())
            setOnClickListener { action() }
            setPadding(dp(13), dp(13), dp(13), dp(13))
        }
    }

    private fun roundedBackground(color: Int, radius: Float) =
        android.graphics.drawable.GradientDrawable().apply {
            setColor(color)
            cornerRadius = radius
        }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    companion object {
        const val EXTRA_STATUS = "status"
        const val EXTRA_IMAGE_PATH = "imagePath"
        const val EXTRA_WIDTH_MM = "widthMm"
        const val EXTRA_HEIGHT_MM = "heightMm"
        const val EXTRA_DEPTH_MM = "depthMm"
        const val EXTRA_METHOD = "method"
        private const val CAMERA_PERMISSION_REQUEST = 913
        private const val MIN_MM = 5.0
        private const val MAX_MM = 5000.0
        private const val MIN_AXIS_ALIGNMENT_RATIO = 0.80
        private const val CENTER_HIT_SAMPLE_COUNT = 10
        private const val CENTER_HIT_SAMPLE_INTERVAL_MS = 30L
        private const val CENTER_HIT_MIN_DURATION_MS = 240L
        private const val CENTER_HIT_MAX_AGE_MS = 600L
        private const val MAX_CENTER_HIT_SPREAD_MM = 12.0
        private const val TRACKING_TIMEOUT_MS = 15_000L
        private const val LIME = 0xFFB9F44A.toInt()

        private const val VERTEX_SHADER = """
            attribute vec4 a_Position;
            attribute vec2 a_TexCoord;
            varying vec2 v_TexCoord;
            void main() {
                gl_Position = a_Position;
                v_TexCoord = a_TexCoord;
            }
        """
        private const val FRAGMENT_SHADER = """
            #extension GL_OES_EGL_image_external : require
            precision mediump float;
            varying vec2 v_TexCoord;
            uniform samplerExternalOES u_Texture;
            void main() {
                gl_FragColor = texture2D(u_Texture, v_TexCoord);
            }
        """
    }
}

private data class PlacedPoint(val anchor: Anchor, val fromDepth: Boolean)

private enum class CenterHitKind { DEPTH, PLANE, POINT }

private data class CenterHitSample(
    val translation: FloatArray,
    val kind: CenterHitKind,
    val timestampMillis: Long,
)

private data class StableCenterHit(
    val pose: Pose,
    val fromDepth: Boolean,
)

private data class MeasurementLine(
    val axis: MeasureAxis,
    val first: PlacedPoint,
    val second: PlacedPoint,
) {
    val usedOnlyDepthPoints: Boolean get() = first.fromDepth && second.fromDepth
    val currentMillimeters: Double
        get() = ArMeasurementMath.axisDistanceMillimeters(
            axis,
            first.anchor.pose.translation,
            second.anchor.pose.translation,
        )
    val currentAlignment: Double
        get() = ArMeasurementMath.alignmentRatio(
            axis,
            first.anchor.pose.translation,
            second.anchor.pose.translation,
        )

    fun detach() {
        first.anchor.detach()
        second.anchor.detach()
    }
}

private data class OverlayLine(
    val first: android.graphics.PointF,
    val second: android.graphics.PointF,
    val label: String,
    val pending: Boolean,
)

private class MeasurementOverlayView(context: Context) : View(context) {
    @Volatile private var lines: List<OverlayLine> = emptyList()
    @Volatile private var pendingLine: OverlayLine? = null
    @Volatile private var reticleValid = false
    private val density = resources.displayMetrics.density
    private val linePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFFB9F44A.toInt()
        strokeWidth = 3f * density
        strokeCap = Paint.Cap.ROUND
    }
    private val pendingPaint = Paint(linePaint).apply {
        pathEffect = DashPathEffect(floatArrayOf(8f * density, 6f * density), 0f)
    }
    private val pointPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
    private val pointCenterPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = 0xFF132238.toInt()
    }
    private val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        textSize = 13f * density
        typeface = Typeface.DEFAULT_BOLD
    }
    private val labelBackground = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.argb(190, 10, 17, 26)
    }

    fun updateLines(value: List<OverlayLine>, pending: OverlayLine?) {
        lines = value
        pendingLine = pending
        postInvalidateOnAnimation()
    }

    fun setReticleValid(value: Boolean) {
        reticleValid = value
        postInvalidateOnAnimation()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        lines.forEach { drawLine(canvas, it) }
        pendingLine?.let { drawLine(canvas, it) }
        val centerX = width / 2f
        val centerY = height / 2f
        val reticle = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 2f * density
            color = if (reticleValid) 0xFFB9F44A.toInt() else Color.WHITE
        }
        canvas.drawCircle(centerX, centerY, 15f * density, reticle)
        canvas.drawLine(centerX - 7f * density, centerY, centerX + 7f * density, centerY, reticle)
        canvas.drawLine(centerX, centerY - 7f * density, centerX, centerY + 7f * density, reticle)
    }

    private fun drawLine(canvas: Canvas, line: OverlayLine) {
        canvas.drawLine(
            line.first.x,
            line.first.y,
            line.second.x,
            line.second.y,
            if (line.pending) pendingPaint else linePaint,
        )
        drawPoint(canvas, line.first)
        drawPoint(canvas, line.second)
        val middleX = (line.first.x + line.second.x) / 2f
        val middleY = (line.first.y + line.second.y) / 2f
        val textWidth = labelPaint.measureText(line.label)
        val padding = 7f * density
        val bounds = RectF(
            middleX - textWidth / 2f - padding,
            middleY - 28f * density,
            middleX + textWidth / 2f + padding,
            middleY - 7f * density,
        )
        canvas.drawRoundRect(bounds, 6f * density, 6f * density, labelBackground)
        canvas.drawText(
            line.label,
            bounds.left + padding,
            bounds.bottom - 5f * density,
            labelPaint,
        )
    }

    private fun drawPoint(canvas: Canvas, point: android.graphics.PointF) {
        canvas.drawCircle(point.x, point.y, 7f * density, pointPaint)
        canvas.drawCircle(point.x, point.y, 3f * density, pointCenterPaint)
    }
}

private object Yuv420Converter {
    fun toJpeg(image: Image, rotationDegrees: Int): ByteArray {
        val width = image.width
        val height = image.height
        val nv21 = ByteArray(width * height * 3 / 2)
        copyPlane(image.planes[0], width, height, nv21, 0, 1)
        copyPlane(image.planes[2], width / 2, height / 2, nv21, width * height, 2)
        copyPlane(image.planes[1], width / 2, height / 2, nv21, width * height + 1, 2)

        val raw = ByteArrayOutputStream()
        check(
            YuvImage(nv21, ImageFormat.NV21, width, height, null).compressToJpeg(
                Rect(0, 0, width, height),
                92,
                raw,
            ),
        )
        if (rotationDegrees == 0) return raw.toByteArray()
        val bytes = raw.toByteArray()
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
        val rotated = Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            GraphicsMatrix().apply { postRotate(rotationDegrees.toFloat()) },
            true,
        )
        val output = ByteArrayOutputStream()
        rotated.compress(Bitmap.CompressFormat.JPEG, 92, output)
        if (rotated !== bitmap) rotated.recycle()
        bitmap.recycle()
        return output.toByteArray()
    }

    private fun copyPlane(
        plane: Image.Plane,
        width: Int,
        height: Int,
        output: ByteArray,
        offset: Int,
        outputStride: Int,
    ) {
        val buffer = plane.buffer
        var outputIndex = offset
        for (row in 0 until height) {
            val rowStart = row * plane.rowStride
            for (column in 0 until width) {
                output[outputIndex] = buffer.get(rowStart + column * plane.pixelStride)
                outputIndex += outputStride
            }
        }
    }
}

private fun formatDistance(millimeters: Double): String = if (millimeters < 1000) {
    "${String.format(java.util.Locale.US, "%.1f", millimeters / 10.0)} cm"
} else {
    "${String.format(java.util.Locale.US, "%.2f", millimeters / 1000.0)} m"
}

private fun floatBufferOf(vararg values: Float): FloatBuffer =
    ByteBuffer.allocateDirect(values.size * 4)
        .order(ByteOrder.nativeOrder())
        .asFloatBuffer()
        .apply {
            put(values)
            position(0)
        }
