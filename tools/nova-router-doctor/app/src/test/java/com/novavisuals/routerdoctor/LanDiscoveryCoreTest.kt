package com.novavisuals.routerdoctor

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class LanDiscoveryCoreTest {
    @Test
    fun limitsA24ScanAndExcludesNetworkBroadcastAndLocalAddress() {
        val hosts = LanDiscoveryCore.targetHosts("192.168.1.10", 24)
        assertEquals(253, hosts.size)
        assertTrue("192.168.1.1" in hosts)
        assertTrue("192.168.1.254" in hosts)
        assertTrue("192.168.1.0" !in hosts)
        assertTrue("192.168.1.255" !in hosts)
        assertTrue("192.168.1.10" !in hosts)
    }

    @Test
    fun handlesSmallPointToPointSubnet() {
        assertEquals(
            listOf("192.168.8.1"),
            LanDiscoveryCore.targetHosts("192.168.8.2", 30)
        )
        assertEquals("192.168.8.0/30", LanDiscoveryCore.networkCidr("192.168.8.2", 30))
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsSubnetLargerThanTheSafeScanLimit() {
        LanDiscoveryCore.targetHosts("192.168.1.10", 23)
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsNonPrivateAddressRanges() {
        LanDiscoveryCore.targetHosts("8.8.8.8", 24)
    }

    @Test
    fun classifiesOnlyAsProbableDeviceRoles() {
        assertEquals(
            "الراوتر / البوابة الافتراضية",
            LanDiscoveryCore.probableRole(setOf(80), true)
        )
        assertTrue(LanDiscoveryCore.probableRole(setOf(554), false).contains("محتملة"))
        assertTrue(LanDiscoveryCore.probableRole(setOf(9100), false).contains("طابعة"))
    }
}
