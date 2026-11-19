package com.novavisuals.routerdoctor

data class WifiSecurityAuditResult(
    val protocolLabel: String,
    val riskScore: Int,
    val riskLabel: String,
    val pmfLabel: String,
    val wpsLabel: String,
    val findings: List<String>
)

/**
 * Passive interpretation of Android ScanResult.capabilities.
 * Scores are transparent configuration heuristics, not exploit probabilities.
 */
object WifiSecurityAudit {
    fun analyze(capabilities: String?): WifiSecurityAuditResult {
        val raw = capabilities.orEmpty().uppercase()
        val hasSae = "SAE" in raw
        val hasPsk = "PSK" in raw
        val hasEap = "EAP" in raw
        val hasOwe = "OWE" in raw
        val hasWpa3 = hasSae || hasOwe || "WPA3" in raw || "SUITE_B_192" in raw
        val hasWpa2 = "WPA2" in raw || hasPsk
        val hasWpa1 = Regex("WPA(?!2|3)").containsMatchIn(raw)
        val hasWep = Regex("(?:^|[\\[\\]_-])WEP(?:$|[\\[\\]_-])").containsMatchIn(raw)
        val hasAnySecurity = hasWpa3 || hasWpa2 || hasWpa1 || hasWep || hasEap
        // Android commonly reports an unencrypted infrastructure network as [ESS].
        // Missing/empty capability data is not evidence that a network is open.
        val hasNetworkModeHint = "ESS" in raw || "IBSS" in raw
        val isOpen = !hasAnySecurity && hasNetworkModeHint
        val isUnknown = !hasAnySecurity && !hasNetworkModeHint
        val pmfRequired = "MFPR" in raw
        val pmfCapable = "MFPC" in raw || pmfRequired
        val wpsAdvertised = "WPS" in raw

        val protocol = when {
            hasSae && hasPsk -> "WPA2/WPA3-Personal (انتقالي)"
            hasSae && hasEap -> "WPA3-Personal/Enterprise (تحقق من تفاصيل AP)"
            hasSae -> "WPA3-Personal (SAE)"
            hasWpa3 && hasEap -> "WPA3-Enterprise (EAP)"
            hasOwe -> "Enhanced Open (OWE)"
            hasEap && hasWpa2 -> "WPA2-Enterprise (EAP)"
            hasEap && hasWpa1 -> "WPA-Enterprise (قديم)"
            hasPsk && hasWpa2 -> "WPA2-Personal (PSK)"
            hasWpa1 -> "WPA قديم"
            hasWep -> "WEP قديم جداً"
            isOpen -> "شبكة مفتوحة (لا يظهر تشفير)"
            isUnknown -> "غير معروف (بيانات الحماية غير كافية)"
            else -> "حماية غير معروفة"
        }

        var score = 0
        val findings = mutableListOf<String>()
        when {
            hasWep -> {
                score += 85
                findings += "WEP قديم وغير آمن؛ يُنصح بتعطيله."
            }
            hasWpa1 -> {
                score += 65
                findings += "تم الإعلان عن WPA القديم؛ استخدم WPA2-AES أو WPA3."
            }
            isOpen -> {
                score += 55
                findings += "لا يظهر تشفير Wi-Fi تقليدي في بيانات المسح."
            }
            hasSae -> findings += "تم رصد SAE المرتبط بـ WPA3."
            hasWpa3 && hasEap -> findings += "تم رصد مؤشرات WPA3-Enterprise؛ لم يتم اختبار المصادقة."
            hasWpa2 -> findings += "تم رصد مؤشرات WPA2؛ لا تكشف هذه البيانات كلمة المرور."
            isUnknown -> findings += "بيانات قدرات نقطة الوصول فارغة أو غير كافية؛ لا يمكن تصنيف الحماية."
        }
        val pmf = when {
            pmfRequired -> "مطلوب (MFPR)"
            pmfCapable -> "مدعوم اختيارياً (MFPC)"
            isUnknown -> "غير معروف (بيانات غير كافية)"
            else -> "غير معلن أو غير متاح"
        }
        if (!pmfCapable && hasAnySecurity) {
            score += 10
            findings += "لم يظهر إعلان PMF في بيانات المسح؛ قد تكون معلومات Android غير مكتملة."
        } else if (pmfRequired) {
            findings += "إطارات الإدارة المحمية PMF معلنة كمتطلب."
        }
        val wps = if (wpsAdvertised) {
            findings += "ظهرت علامة WPS في بيانات القدرات؛ يلزم تحقق إداري، ولا يثبت ذلك وجود ثغرة."
            "معلن في بيانات المسح (غير مؤكد)"
        } else {
            "غير ظاهر / غير متاح"
        }
        if (hasOwe) findings += "OWE يوفر تشفيراً للشبكة المفتوحة المتوافقة لكنه لا يثبت هوية المستخدم."
        if (findings.isEmpty()) findings += "لا توجد مؤشرات كافية؛ يلزم فحص إعدادات الراوتر بإذن إداري."
        score = score.coerceIn(0, 100)
        val label = when {
            score >= 70 -> "مرتفع"
            score >= 40 -> "متوسط"
            score >= 15 -> "منخفض"
            else -> "مؤشرات محدودة"
        }
        return WifiSecurityAuditResult(protocol, score, label, pmf, wps, findings)
    }
}
