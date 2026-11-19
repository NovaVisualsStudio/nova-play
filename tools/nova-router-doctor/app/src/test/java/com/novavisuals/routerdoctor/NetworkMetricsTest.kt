package com.novavisuals.routerdoctor

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class NetworkMetricsTest {
    @Test
    fun computesMeanMedianP95AndVariation() {
        val stats = NetworkMetrics.fromSamples(listOf(10.0, 20.0, 30.0, 40.0), failedCount = 1)
        assertEquals(25.0, stats.mean, 0.0001)
        assertEquals(25.0, stats.median, 0.0001)
        assertEquals(38.5, stats.p95, 0.0001)
        assertEquals(10.0, stats.meanAbsoluteDelta, 0.0001)
        assertEquals(20.0, stats.lossPercent, 0.0001)
    }

    @Test
    fun allFailedSamplesReportHundredPercentFailure() {
        val stats = NetworkMetrics.fromSamples(emptyList(), failedCount = 3)
        assertEquals(100.0, stats.lossPercent, 0.0001)
        assertEquals(3, stats.failedCount)
        assertTrue(stats.mean.isNaN())
    }

    @Test
    fun throughputUsesDecimalMegabitsPerSecond() {
        assertEquals(8.0, NetworkMetrics.throughputMbps(1_000_000, 1.0), 0.0001)
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsInvalidElapsedTime() {
        NetworkMetrics.throughputMbps(1000, 0.0)
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsNegativeLatency() {
        NetworkMetrics.fromSamples(listOf(-1.0))
    }
}
