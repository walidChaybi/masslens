package com.masslens.mass_lens

import kotlin.math.sqrt

enum class MeasureAxis(val label: String) {
    WIDTH("Length"),
    HEIGHT("Height"),
    DEPTH("Depth"),
}

object ArMeasurementMath {
    fun distanceMillimeters(first: FloatArray, second: FloatArray): Double {
        require(first.size >= 3 && second.size >= 3)
        val dx = (second[0] - first[0]).toDouble()
        val dy = (second[1] - first[1]).toDouble()
        val dz = (second[2] - first[2]).toDouble()
        return sqrt(dx * dx + dy * dy + dz * dz) * 1000.0
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
