package com.novavisuals.routerdoctor

import kotlin.math.abs
import kotlin.math.sqrt

/**
 * Deterministic, dependency-free statistics for network measurements.
 * Latency jitter here is the mean absolute delta between adjacent samples;
 * it is deliberately not presented as RFC 3550 RTP inter-arrival jitter.
 */
data class SampleStatistics(
    val count: Int,
    val failedCount: Int,
    val lossPercent: Double,
    val mean: Double,
    val median: Double,
    val p95: Double,
    val standardDeviation: Double,
    val meanAbsoluteDelta: Double
)

object NetworkMetrics {
    fun fromSamples(samples: List<Double>, failedCount: Int = 0): SampleStatistics {
        require(failedCount >= 0) { "failedCount must be non-negative" }
        require(samples.all { it.isFinite() && it >= 0.0 }) {
            "samples must be finite, non-negative values"
        }
        val total = samples.size + failedCount
        require(total > 0) { "at least one successful or failed sample is required" }

        if (samples.isEmpty()) {
            return SampleStatistics(
                count = 0,
                failedCount = failedCount,
                lossPercent = 100.0,
                mean = Double.NaN,
                median = Double.NaN,
                p95 = Double.NaN,
                standardDeviation = Double.NaN,
                meanAbsoluteDelta = Double.NaN
            )
        }

        val sorted = samples.sorted()
        val mean = samples.average()
        val variance = samples.sumOf { value ->
            val delta = value - mean
            delta * delta
        } / samples.size
        val deltas = samples.zipWithNext { left, right -> abs(right - left) }
        return SampleStatistics(
            count = samples.size,
            failedCount = failedCount,
            lossPercent = failedCount * 100.0 / total,
            mean = mean,
            median = percentile(sorted, 0.50),
            p95 = percentile(sorted, 0.95),
            standardDeviation = sqrt(variance),
            meanAbsoluteDelta = if (deltas.isEmpty()) 0.0 else deltas.average()
        )
    }

    fun throughputMbps(bytes: Long, elapsedSeconds: Double): Double {
        require(bytes >= 0L) { "bytes must be non-negative" }
        require(elapsedSeconds.isFinite() && elapsedSeconds > 0.0) {
            "elapsedSeconds must be finite and positive"
        }
        return bytes.toDouble() * 8.0 / elapsedSeconds / 1_000_000.0
    }

    private fun percentile(sorted: List<Double>, quantile: Double): Double {
        require(sorted.isNotEmpty())
        val position = (sorted.size - 1) * quantile
        val lower = position.toInt()
        val upper = kotlin.math.ceil(position).toInt()
        if (lower == upper) return sorted[lower]
        val fraction = position - lower
        return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction
    }
}
