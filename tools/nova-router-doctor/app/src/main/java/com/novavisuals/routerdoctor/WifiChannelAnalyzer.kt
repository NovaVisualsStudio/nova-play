package com.novavisuals.routerdoctor

import kotlin.math.abs
import kotlin.math.pow

data class WifiObservation(val channel: Int, val rssiDbm: Int)
data class WifiChannelScore(val channel: Int, val score: Double, val visibleAccessPoints: Int)

/**
 * Heuristic channel comparison from Android scan results.
 * This estimates neighboring-AP pressure only; it is NOT RF airtime utilization
 * or a spectrum-analyzer measurement.
 */
object WifiChannelAnalyzer {
    private val common24GhzChannels = listOf(1, 6, 11)

    fun channelForFrequencyMhz(frequency: Int): Pair<String, Int>? = when (frequency) {
        in 2412..2472 -> "2.4 GHz" to ((frequency - 2407) / 5)
        2484 -> "2.4 GHz" to 14
        in 5000..5895 -> "5 GHz" to ((frequency - 5000) / 5)
        in 5925..7125 -> "6 GHz" to ((frequency - 5950) / 5)
        else -> null
    }

    fun rank24GhzChannels(observations: List<WifiObservation>): List<WifiChannelScore> {
        val valid = observations.filter { it.channel in 1..14 && it.rssiDbm in -100..-1 }
        return common24GhzChannels.map { candidate ->
            val pressure = valid.sumOf { ap ->
                val separation = abs(ap.channel - candidate)
                val overlap = (1.0 - separation / 5.0).coerceAtLeast(0.0)
                val signalWeight = 10.0.pow((ap.rssiDbm + 100) / 20.0)
                overlap * signalWeight
            }
            WifiChannelScore(
                channel = candidate,
                score = pressure,
                visibleAccessPoints = valid.count { abs(it.channel - candidate) <= 4 }
            )
        }.sortedWith(compareBy<WifiChannelScore> { it.score }.thenBy { it.channel })
    }

    fun signalQualityLabel(rssiDbm: Int): String = when {
        rssiDbm >= -50 -> "قوية جداً"
        rssiDbm >= -60 -> "قوية"
        rssiDbm >= -67 -> "جيدة"
        rssiDbm >= -75 -> "متوسطة"
        rssiDbm >= -85 -> "ضعيفة"
        else -> "ضعيفة جداً"
    }
}
