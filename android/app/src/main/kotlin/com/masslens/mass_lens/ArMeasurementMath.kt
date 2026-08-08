package com.masslens.mass_lens

import kotlin.math.abs
import kotlin.math.sqrt

enum class MeasureAxis(val label: String) {
    WIDTH("Length"),
    HEIGHT("Height"),
    DEPTH("Depth"),
}

object ArMeasurementMath {
    fun distanceMillimeters(first: FloatArray, second: FloatArray): Double {
        val (dx, dy, dz) = deltas(first, second)
        return sqrt(dx * dx + dy * dy + dz * dz) * 1000.0
    }

    /**
     * Measures only the world-space component that belongs to the requested
     * axis. ARCore keeps Y aligned with gravity, so height ignores small
     * horizontal targeting errors while length/depth ignore vertical drift.
     */
    fun axisDistanceMillimeters(
        axis: MeasureAxis,
        first: FloatArray,
        second: FloatArray,
    ): Double {
        val (dx, dy, dz) = deltas(first, second)
        return when (axis) {
            MeasureAxis.HEIGHT -> abs(dy)
            MeasureAxis.WIDTH,
            MeasureAxis.DEPTH,
            -> sqrt(dx * dx + dz * dz)
        } * 1000.0
    }

    fun alignmentRatio(
        axis: MeasureAxis,
        first: FloatArray,
        second: FloatArray,
    ): Double {
        val fullDistance = distanceMillimeters(first, second)
        if (fullDistance <= 0.0) return 0.0
        return axisDistanceMillimeters(axis, first, second) / fullDistance
    }

    /** Returns the component-wise median when every sample is close to it. */
    fun stableTranslation(
        samples: List<FloatArray>,
        maxSpreadMillimeters: Double,
    ): FloatArray? {
        require(maxSpreadMillimeters > 0.0 && maxSpreadMillimeters.isFinite())
        if (samples.isEmpty() || samples.any { it.size < 3 }) return null
        val median = FloatArray(3) { axis ->
            samples.map { it[axis] }.sorted()[samples.size / 2]
        }
        return median.takeIf { center ->
            samples.all {
                distanceMillimeters(it, center) <= maxSpreadMillimeters
            }
        }
    }

    private fun deltas(
        first: FloatArray,
        second: FloatArray,
    ): Triple<Double, Double, Double> {
        require(first.size >= 3 && second.size >= 3)
        return Triple(
            (second[0] - first[0]).toDouble(),
            (second[1] - first[1]).toDouble(),
            (second[2] - first[2]).toDouble(),
        )
    }
}

class ArMeasurementState {
    private val values = mutableListOf<Double>()

    val completedCount: Int get() = values.size
    val canFinish: Boolean get() = values.size >= 2
    val currentAxis: MeasureAxis get() = when (values.size) {
        0 -> MeasureAxis.WIDTH
        1 -> MeasureAxis.HEIGHT
        else -> MeasureAxis.DEPTH
    }

    fun complete(millimeters: Double): MeasureAxis {
        require(millimeters.isFinite() && millimeters in 5.0..5000.0)
        check(values.size < MeasureAxis.entries.size)
        val axis = currentAxis
        values += millimeters
        return axis
    }

    fun undo(): Double? = if (values.isEmpty()) null else values.removeLast()

    fun reset() = values.clear()

    fun value(axis: MeasureAxis): Double? = values.getOrNull(axis.ordinal)
}

fun encodeArMeasurementResult(
    imagePath: String,
    widthMm: Double,
    heightMm: Double,
    depthMm: Double?,
    method: String,
): Map<String, Any> {
    val dimensions = mutableMapOf<String, Any>(
        "widthMm" to widthMm,
        "heightMm" to heightMm,
        "method" to method,
    )
    if (depthMm != null) dimensions["depthMm"] = depthMm
    return mapOf(
        "status" to "completed",
        "imagePath" to imagePath,
        "dimensions" to dimensions,
    )
}
