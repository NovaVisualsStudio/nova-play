package com.novavisuals.routerdoctor

import kotlin.math.abs
import kotlin.math.sqrt

/**
 * Deterministic, dependency-free statistics for network measurements.
 * Latency jitter here is the mean absolute delta between adjacent samples;
 * it is deliberately not presented as RFC 3550 RTP inter-arrival jitter.
 */
data class LoadedLatencyAssessment(
    val baselineP95Ms: Double,
    val loadedP95Ms: Double,
    val increaseMs: Double,
    val label: String
)

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

    /**
     * Heuristic classification of the added P95 latency under load.
     * It is not a standards certification; callers must disclose the probe type.
     */
    fun assessLoadedLatency(baselineP95Ms: Double, loadedP95Ms: Double): LoadedLatencyAssessment {
        require(baselineP95Ms.isFinite() && baselineP95Ms >= 0.0)
        require(loadedP95Ms.isFinite() && loadedP95Ms >= 0.0)
        val increase = (loadedP95Ms - baselineP95Ms).coerceAtLeast(0.0)
        val label = when {
            increase <= 5.0 -> "ممتاز — زيادة طفيفة"
            increase <= 15.0 -> "جيد — ازدحام محدود"
            increase <= 30.0 -> "متوسط — قد يظهر تأخير ملحوظ"
            increase <= 60.0 -> "مرتفع — تأخير واضح تحت الحمل"
            else -> "شديد — ارتفاع كبير في زمن الاستجابة"
        }
        return LoadedLatencyAssessment(baselineP95Ms, loadedP95Ms, increase, label)
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
