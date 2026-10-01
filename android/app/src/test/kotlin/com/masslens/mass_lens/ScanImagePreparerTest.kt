package com.masslens.mass_lens

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ScanImagePreparerTest {
    private fun gray(value: Int) = (0xff shl 24) or (value shl 16) or (value shl 8) or value

    @Test
    fun boundsLongestSideTo1024() {
        assertEquals(1024 to 512, ScanImagePreparer.targetSize(1200, 600))
        assertEquals(768 to 1024, ScanImagePreparer.targetSize(3000, 4000))
        assertEquals(800 to 600, ScanImagePreparer.targetSize(800, 600))
    }

    @Test
    fun flatDarkImageIsDarkAndBlurry() {
        val pixels = IntArray(400 * 400) { gray(10) }
        val (dark, blurry) = ScanImagePreparer.qualityFlags(pixels, 400, 400)
        assertTrue(dark)
        assertTrue(blurry)
    }

    @Test
    fun brightDetailedImageHasNoWarnings() {
        val w = 512
        val h = 512
        val pixels = IntArray(w * h) { i ->
            val x = i % w
            val y = i / w
            if (((x / 2) + (y / 2)) % 2 == 0) gray(230) else gray(90)
        }
        val (dark, blurry) = ScanImagePreparer.qualityFlags(pixels, w, h)
        assertFalse(dark)
        assertFalse(blurry)
    }
}
