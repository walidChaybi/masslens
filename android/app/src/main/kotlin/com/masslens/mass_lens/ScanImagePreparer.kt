package com.masslens.mass_lens

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageDecoder
import android.graphics.Matrix
import android.media.ExifInterface
import android.os.Build
import java.io.File
import java.util.UUID
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Prepares a scan photo for upload entirely in native code, on a worker thread.
 *
 * This replaces the Dart `Isolate.run` + `package:image` path, which decoded
 * full-size photos inside the app's isolate group and was the source of the
 * main-thread ANRs reported in Android Vitals
 * (dart::IsolateGroup::IncreaseMutatorCount).
 */
internal object ScanImagePreparer {
    const val MIN_SIDE = 320
    const val MAX_SIDE = 1024
    private const val QUALITY_SIDE = 256
    private const val JPEG_QUALITY = 82
    private const val OUTPUT_PREFIX = "scan_prepared_"

    class PrepareException(val code: String, message: String) : Exception(message)

    data class Prepared(
        val path: String,
        val width: Int,
        val height: Int,
        val dark: Boolean,
        val blurry: Boolean,
    ) {
        fun toMap(): Map<String, Any> = mapOf(
            "path" to path,
            "width" to width,
            "height" to height,
            "dark" to dark,
            "blurry" to blurry,
        )
    }

    fun prepare(sourcePath: String, cacheDir: File): Prepared {
        val source = File(sourcePath)
        if (!source.isFile) throw PrepareException("missing", "Photo not found")

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(sourcePath, bounds)
        val rawWidth = bounds.outWidth
        val rawHeight = bounds.outHeight
        if (rawWidth > 0 && rawHeight > 0 && (rawWidth < MIN_SIDE || rawHeight < MIN_SIDE)) {
            throw PrepareException("tooSmall", "Photo is too small")
        }

        val bitmap = try {
            decodeBounded(source)
        } catch (error: PrepareException) {
            throw error
        } catch (_: Throwable) {
            null
        } ?: throw PrepareException("corrupt", "Photo could not be decoded")

        try {
            if (bitmap.width < MIN_SIDE || bitmap.height < MIN_SIDE) {
                // Only reachable when bounds were unavailable (e.g. HEIF on old devices).
                throw PrepareException("tooSmall", "Photo is too small")
            }
            val pixels = IntArray(bitmap.width * bitmap.height)
            bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
            val flags = qualityFlags(pixels, bitmap.width, bitmap.height)

            cleanOldOutputs(cacheDir)
            val output = File(cacheDir, "$OUTPUT_PREFIX${UUID.randomUUID()}.jpg")
            // Re-encoding drops EXIF/GPS metadata before anything is uploaded.
            output.outputStream().use {
                if (!bitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, it)) {
                    throw PrepareException("corrupt", "Photo could not be encoded")
                }
            }
            return Prepared(output.absolutePath, bitmap.width, bitmap.height, flags.first, flags.second)
        } finally {
            bitmap.recycle()
        }
    }

    /** Longest side scaled down to [MAX_SIDE]; EXIF orientation applied. */
    private fun decodeBounded(source: File): Bitmap? {
        if (Build.VERSION.SDK_INT >= 28) {
            return ImageDecoder.decodeBitmap(ImageDecoder.createSource(source)) { decoder, info, _ ->
                decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
                val width = info.size.width
                val height = info.size.height
                if (width < MIN_SIDE || height < MIN_SIDE) {
                    throw PrepareException("tooSmall", "Photo is too small")
                }
                val target = targetSize(width, height)
                if (target.first != width || target.second != height) {
                    decoder.setTargetSize(target.first, target.second)
                }
            }
        }

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(source.path, bounds)
        var sample = 1
        while (max(bounds.outWidth, bounds.outHeight) / (sample * 2) >= MAX_SIDE) sample *= 2
        val decoded = BitmapFactory.decodeFile(
            source.path,
            BitmapFactory.Options().apply { inSampleSize = sample },
        ) ?: return null

        val target = targetSize(decoded.width, decoded.height)
        val scaled = if (target.first != decoded.width || target.second != decoded.height) {
            Bitmap.createScaledBitmap(decoded, target.first, target.second, true)
                .also { if (it !== decoded) decoded.recycle() }
        } else decoded

        val rotation = try {
            when (ExifInterface(source.path).getAttributeInt(
                ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL
            )) {
                ExifInterface.ORIENTATION_ROTATE_90 -> 90f
                ExifInterface.ORIENTATION_ROTATE_180 -> 180f
                ExifInterface.ORIENTATION_ROTATE_270 -> 270f
                else -> 0f
            }
        } catch (_: Exception) { 0f }
        if (rotation == 0f) return scaled
        val rotated = Bitmap.createBitmap(
            scaled, 0, 0, scaled.width, scaled.height,
            Matrix().apply { postRotate(rotation) }, true,
        )
        if (rotated !== scaled) scaled.recycle()
        return rotated
    }

    fun targetSize(width: Int, height: Int): Pair<Int, Int> {
        val longest = max(width, height)
        if (longest <= MAX_SIDE) return width to height
        return if (width >= height) {
            MAX_SIDE to (height * MAX_SIDE / width).coerceAtLeast(1)
        } else {
            (width * MAX_SIDE / height).coerceAtLeast(1) to MAX_SIDE
        }
    }

    /**
     * Same heuristics as the former Dart implementation: mean luminance < 45 is
     * dark, Laplacian variance < 55 on a ~256px area-averaged copy is blurry.
     * Returns (dark, blurry).
     */
    fun qualityFlags(argb: IntArray, width: Int, height: Int): Pair<Boolean, Boolean> {
        val full = DoubleArray(width * height)
        for (i in full.indices) {
            val p = argb[i]
            full[i] = 0.2126 * ((p shr 16) and 0xff) +
                0.7152 * ((p shr 8) and 0xff) +
                0.0722 * (p and 0xff)
        }

        var w = width
        var h = height
        var lum = full
        if (width > QUALITY_SIDE || height > QUALITY_SIDE) {
            if (width >= height) {
                w = QUALITY_SIDE
                h = (height * QUALITY_SIDE / width).coerceAtLeast(1)
            } else {
                h = QUALITY_SIDE
                w = (width * QUALITY_SIDE / height).coerceAtLeast(1)
            }
            lum = areaAverage(full, width, height, w, h)
        }

        val mean = lum.average()
        var count = 0
        var sum = 0.0
        var sumSquares = 0.0
        for (y in 1 until h - 1) {
            for (x in 1 until w - 1) {
                val i = y * w + x
                val value = 4 * lum[i] - lum[i - 1] - lum[i + 1] - lum[i - w] - lum[i + w]
                sum += value
                sumSquares += value * value
                count++
            }
        }
        val n = max(1, count).toDouble()
        val lapMean = sum / n
        val variance = sumSquares / n - lapMean * lapMean
        return (mean < 45.0) to (variance < 55.0)
    }

    private fun areaAverage(src: DoubleArray, sw: Int, sh: Int, dw: Int, dh: Int): DoubleArray {
        val out = DoubleArray(dw * dh)
        for (dy in 0 until dh) {
            val y0 = dy * sh / dh
            val y1 = max(y0 + 1, ((dy + 1) * sh / dh))
            for (dx in 0 until dw) {
                val x0 = dx * sw / dw
                val x1 = max(x0 + 1, ((dx + 1) * sw / dw))
                var total = 0.0
                for (y in y0 until y1) {
                    val row = y * sw
                    for (x in x0 until x1) total += src[row + x]
                }
                out[dy * dw + dx] = total / ((y1 - y0) * (x1 - x0))
            }
        }
        return out
    }

    private fun cleanOldOutputs(cacheDir: File) {
        val cutoff = System.currentTimeMillis() - 10 * 60 * 1000
        cacheDir.listFiles { file -> file.name.startsWith(OUTPUT_PREFIX) && file.lastModified() < cutoff }
            ?.forEach { it.delete() }
    }
}
