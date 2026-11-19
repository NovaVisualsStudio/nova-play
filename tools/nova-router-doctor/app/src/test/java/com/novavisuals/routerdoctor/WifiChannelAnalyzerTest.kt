package com.novavisuals.routerdoctor

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WifiChannelAnalyzerTest {
    @Test
    fun mapsCommonRadioFrequenciesToChannels() {
        assertEquals("2.4 GHz" to 1, WifiChannelAnalyzer.channelForFrequencyMhz(2412))
        assertEquals("2.4 GHz" to 14, WifiChannelAnalyzer.channelForFrequencyMhz(2484))
        assertEquals("5 GHz" to 36, WifiChannelAnalyzer.channelForFrequencyMhz(5180))
        assertEquals("6 GHz" to 1, WifiChannelAnalyzer.channelForFrequencyMhz(5955))
        assertEquals(null, WifiChannelAnalyzer.channelForFrequencyMhz(900))
    }

    @Test
    fun ranksClearChannelAheadOfStrongNearbyInterference() {
        val ranked = WifiChannelAnalyzer.rank24GhzChannels(
            listOf(WifiObservation(channel = 6, rssiDbm = -35))
        )
        assertEquals(1, ranked.first().channel)
        assertTrue(ranked.last().score > ranked.first().score)
    }

    @Test
    fun ignoresInvalidObservations() {
        val ranked = WifiChannelAnalyzer.rank24GhzChannels(
            listOf(WifiObservation(channel = 40, rssiDbm = -40), WifiObservation(6, -120))
        )
        assertTrue(ranked.all { it.score == 0.0 })
    }
}
