package com.masslens.mass_lens

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ArMeasurementMathTest {
    @Test
    fun convertsThreeDimensionalDistanceToMillimeters() {
        val result = ArMeasurementMath.distanceMillimeters(
            floatArrayOf(0f, 0f, 0f),
            floatArrayOf(0.3f, 0.4f, 0f),
        )
        assertEquals(500.0, result, 0.01)
    }

    @Test
    fun advancesAxesAndSupportsUndoAndReset() {
        val state = ArMeasurementState()
        assertEquals(MeasureAxis.WIDTH, state.currentAxis)
        assertFalse(state.canFinish)

        assertEquals(MeasureAxis.WIDTH, state.complete(320.0))
        assertEquals(MeasureAxis.HEIGHT, state.currentAxis)
        assertEquals(MeasureAxis.HEIGHT, state.complete(210.0))
        assertTrue(state.canFinish)
        assertEquals(MeasureAxis.DEPTH, state.currentAxis)

        assertEquals(210.0, state.undo()!!, 0.01)
        assertFalse(state.canFinish)
        assertEquals(MeasureAxis.HEIGHT, state.currentAxis)
        state.reset()
        assertEquals(0, state.completedCount)
        assertNull(state.value(MeasureAxis.WIDTH))
    }

    @Test
    fun encodesMethodChannelResultWithOptionalDepth() {
        val result = encodeArMeasurementResult(
            imagePath = "/cache/object.jpg",
            widthMm = 320.0,
            heightMm = 210.0,
            depthMm = 180.0,
            method = "arcore_plane",
        )

        assertEquals("completed", result["status"])
        assertEquals("/cache/object.jpg", result["imagePath"])
        assertEquals(
            mapOf(
                "widthMm" to 320.0,
                "heightMm" to 210.0,
                "depthMm" to 180.0,
                "method" to "arcore_plane",
            ),
            result["dimensions"],
        )
    }
}
