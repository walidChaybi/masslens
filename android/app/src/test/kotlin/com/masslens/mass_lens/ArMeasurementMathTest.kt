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
    fun measuresLengthAndHeightAlongTheirWorldAxes() {
        val first = floatArrayOf(0f, 0f, 0f)
        val second = floatArrayOf(0.3f, 0.4f, 0f)

        assertEquals(
            300.0,
            ArMeasurementMath.axisDistanceMillimeters(
                MeasureAxis.WIDTH,
                first,
                second,
            ),
            0.01,
        )
        assertEquals(
            400.0,
            ArMeasurementMath.axisDistanceMillimeters(
                MeasureAxis.HEIGHT,
                first,
                second,
            ),
            0.01,
        )
        assertEquals(
            0.6,
            ArMeasurementMath.alignmentRatio(MeasureAxis.WIDTH, first, second),
            0.001,
        )
        assertEquals(
            0.8,
            ArMeasurementMath.alignmentRatio(MeasureAxis.HEIGHT, first, second),
            0.001,
        )
    }

    @Test
    fun acceptsStableMedianAndRejectsAnOutlier() {
        val stable = listOf(
            floatArrayOf(0.100f, 0.200f, -0.400f),
            floatArrayOf(0.101f, 0.199f, -0.401f),
            floatArrayOf(0.099f, 0.201f, -0.399f),
            floatArrayOf(0.100f, 0.200f, -0.400f),
        )

        val median = ArMeasurementMath.stableTranslation(stable, 8.0)
        requireNotNull(median)
        assertEquals(0.100, median[0].toDouble(), 0.001)
        assertEquals(0.200, median[1].toDouble(), 0.001)
        assertEquals(-0.400, median[2].toDouble(), 0.001)

        val unstable = stable + floatArrayOf(0.140f, 0.200f, -0.400f)
        assertNull(ArMeasurementMath.stableTranslation(unstable, 8.0))
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
