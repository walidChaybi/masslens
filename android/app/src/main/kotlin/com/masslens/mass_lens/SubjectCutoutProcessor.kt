package com.masslens.mass_lens

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.subject.SubjectSegmentation
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenterOptions
import java.io.File
import java.io.FileOutputStream

/** Shared on-device subject extraction; no photo leaves the phone here. */
internal class SubjectCutoutProcessor {
    val segmenter = SubjectSegmentation.getClient(
        SubjectSegmenterOptions.Builder().enableForegroundBitmap().build()
    )

    fun process(image: InputImage, completion: (Bitmap?) -> Unit) {
        segmenter.process(image)
            .addOnSuccessListener { completion(it.foregroundBitmap) }
            .addOnFailureListener { completion(null) }
    }

    companion object {
        fun outline(bitmap: Bitmap): Bitmap {
            val scaled = Bitmap.createScaledBitmap(bitmap, 256,
                (bitmap.height * 256f / bitmap.width).toInt().coerceAtLeast(1), true)
            val width = scaled.width
            val height = scaled.height
            val pixels = IntArray(width * height)
            scaled.getPixels(pixels, 0, width, 0, 0, width, height)
            val edges = IntArray(pixels.size)
            for (y in 2 until height - 2) for (x in 2 until width - 2) {
                val i = y * width + x
                if ((pixels[i] ushr 24) < 128) continue
                if ((pixels[i - 2] ushr 24) < 128 || (pixels[i + 2] ushr 24) < 128 ||
                    (pixels[i - width * 2] ushr 24) < 128 || (pixels[i + width * 2] ushr 24) < 128) {
                    edges[i] = 0xffffffff.toInt()
                }
            }
            return Bitmap.createBitmap(edges, width, height, Bitmap.Config.ARGB_8888)
        }
    }
}
