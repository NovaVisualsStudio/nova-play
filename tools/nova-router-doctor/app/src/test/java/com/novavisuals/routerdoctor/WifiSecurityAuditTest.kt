package com.novavisuals.routerdoctor

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WifiSecurityAuditTest {
    @Test fun identifiesWpa3SaeAndRequiredPmf() {
        val result = WifiSecurityAudit.analyze("[WPA3-SAE-CCMP][MFPR][MFPC][ESS]")
        assertEquals("WPA3-Personal (SAE)", result.protocolLabel)
        assertEquals("مطلوب (MFPR)", result.pmfLabel)
        assertTrue(result.riskScore < 40)
    }

    @Test fun identifiesWpa2Personal() {
        val result = WifiSecurityAudit.analyze("[WPA2-PSK-CCMP][ESS]")
        assertEquals("WPA2-Personal (PSK)", result.protocolLabel)
    }

    @Test fun identifiesTransitionMode() {
        val result = WifiSecurityAudit.analyze("[WPA2-PSK-CCMP][WPA3-SAE-CCMP][ESS]")
        assertTrue(result.protocolLabel.contains("انتقالي"))
    }

    @Test fun identifiesWpa3Enterprise() {
        val result = WifiSecurityAudit.analyze("[WPA3-EAP-SUITE_B_192][MFPR][MFPC]")
        assertEquals("WPA3-Enterprise (EAP)", result.protocolLabel)
    }

    @Test fun flagsLegacyWep() {
        val result = WifiSecurityAudit.analyze("[WEP][ESS]")
        assertEquals("WEP قديم جداً", result.protocolLabel)
        assertTrue(result.riskScore >= 80)
    }

    @Test fun distinguishesOweFromUnencryptedOpen() {
        assertEquals("Enhanced Open (OWE)", WifiSecurityAudit.analyze("[OWE][ESS]").protocolLabel)
        assertEquals("مفتوحة أو غير محددة", WifiSecurityAudit.analyze("[ESS]").protocolLabel)
    }

    @Test fun neverClaimsToRecoverPassword() {
        val result = WifiSecurityAudit.analyze("[WPA2-PSK-CCMP][ESS]")
        assertTrue(result.findings.any { it.contains("لا تكشف") })
    }
}
