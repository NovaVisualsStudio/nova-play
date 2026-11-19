package com.novavisuals.routerdoctor

import android.app.Activity
import android.app.AlertDialog
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale
import java.util.concurrent.Executors

/**
 * Read-only network lab. Speed measurements use Cloudflare's public speed-test
 * endpoints; no router credentials or configuration are accessed.
 */
object NetworkLab {
    private const val DOWNLOAD_BYTES = 8_000_000
    private const val UPLOAD_BYTES = 2_000_000
    private val executor = Executors.newSingleThreadExecutor()
    private val loadExecutor = Executors.newFixedThreadPool(2)
    private val main = Handler(Looper.getMainLooper())

    fun show(activity: Activity) {
        val root = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(24, 18, 24, 12)
        }
        val output = TextView(activity).apply {
            textSize = 14f
            text = "اختر نوع الفحص. اختبار السرعة يستهلك تقريباً 10 MB من البيانات."
            setTextIsSelectable(true)
        }
        val wifiButton = Button(activity).apply {
            text = "تحليل اتصال Wi-Fi الحالي"
        }
        val speedButton = Button(activity).apply {
            text = "قياس سرعة الإنترنت"
        }
        val bufferbloatButton = Button(activity).apply {
            text = "اختبار الازدحام وBufferbloat (تقريبي)"
        }
        val lanButton = Button(activity).apply {
            text = "اكتشاف أجهزة الشبكة المحلية"
        }
        val closeButton = Button(activity).apply {
            text = "إغلاق"
        }
        root.addView(wifiButton)
        root.addView(speedButton)
        root.addView(bufferbloatButton)
        root.addView(lanButton)
        root.addView(ScrollView(activity).apply {
            addView(output)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 520
            )
        })
        root.addView(closeButton)
        val dialog = AlertDialog.Builder(activity)
            .setTitle("مختبر NOVA للشبكات")
            .setView(root)
            .create()
        val setBusy: (Boolean) -> Unit = { busy ->
            listOf(wifiButton, speedButton, bufferbloatButton, lanButton)
                .forEach { it.isEnabled = !busy }
        }
        closeButton.setOnClickListener { dialog.dismiss() }

        bufferbloatButton.setOnClickListener {
            setBusy(true)
            output.text = "جارٍ قياس زمن الاستجابة قبل الضغط وأثناء تنزيل/رفع متزامنين. قد يستهلك الاختبار نحو 15 MB..."
            executor.execute {
                val result = runLoadedLatencyTest()
                main.post {
                    if (dialog.isShowing) output.text = result
                    setBusy(false)
                }
            }
        }

        lanButton.setOnClickListener {
            setBusy(true)
            output.text = "جارٍ فحص عناوين الشبكة المحلية ومنافذ TCP الشائعة فقط. لا يجري تسجيل دخول أو تغيير إعدادات..."
            executor.execute {
                val result = LanDiscovery.run(activity.applicationContext)
                main.post {
                    if (dialog.isShowing) output.text = result
                    setBusy(false)
                }
            }
        }

        wifiButton.setOnClickListener {
            setBusy(true)
            output.text = "جارٍ تحليل اتصال Wi-Fi..."
            executor.execute {
                val result = inspectWifi(activity)
                main.post {
                    if (dialog.isShowing) output.text = result
                    setBusy(false)
                }
            }
        }

        speedButton.setOnClickListener {
            setBusy(true)
            output.text = "جارٍ قياس زمن الاستجابة والتنزيل والرفع. أبقِ التطبيق مفتوحاً ولا تنتقل بين Wi-Fi وبيانات الهاتف..."
            executor.execute {
                val result = runSpeedTest()
                main.post {
                    if (dialog.isShowing) output.text = result
                    setBusy(false)
                }
            }
        }
        dialog.show()
    }

    private fun inspectWifi(context: Context): String {
        val lines = mutableListOf<String>()
        lines += "=== حالة الشبكة النشطة ==="
        try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = cm.activeNetwork
            val caps = network?.let { cm.getNetworkCapabilities(it) }
            val props = network?.let { cm.getLinkProperties(it) }
            val isWifi = caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
            val isCell = caps?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true
            lines += "نوع الاتصال: " + when {
                isWifi -> "Wi-Fi"
                isCell -> "بيانات الهاتف"
                else -> "غير معروف / لا يوجد اتصال نشط"
            }
            lines += "الإنترنت متحقق من Android: " +
                if (caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED) == true) "نعم" else "لا أو غير مؤكد"
            lines += "اتصال غير محدود: " +
                if (caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED) == true) "نعم" else "لا / غير معروف"
            if (props != null) {
                lines += "عنوان IP المحلي: " + (props.linkAddresses.firstOrNull()?.address?.hostAddress ?: "غير متاح")
                lines += "البوابة: " + (props.routes.firstOrNull { it.isDefaultRoute }?.gateway?.hostAddress ?: "غير متاحة")
                lines += "DNS: " + (props.dnsServers.joinToString { it.hostAddress ?: "" }.ifBlank { "غير متاح" })
                lines += "واجهات الشبكة: " + (props.interfaceName ?: "غير معروفة")
            }
        } catch (e: Exception) {
            lines += "تعذر قراءة معلومات الاتصال: ${e.javaClass.simpleName}"
        }

        lines += ""
        lines += "=== تفاصيل Wi-Fi من Android ==="
        try {
            @Suppress("DEPRECATION")
            val info = (context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager).connectionInfo
            @Suppress("DEPRECATION")
            val ssid = info.ssid?.takeIf { it.isNotBlank() && it != "<unknown ssid>" } ?: "محجوب من Android أو غير متاح"
            lines += "اسم الشبكة (SSID): $ssid"
            lines += "قوة الإشارة: ${info.rssi} dBm — ${signalLabel(info.rssi)}"
            lines += "سرعة الربط المتفاوض عليها: ${info.linkSpeed} Mbps (ليست سرعة الإنترنت)"
            lines += "التردد: ${info.frequency} MHz — ${bandLabel(info.frequency)}"
            lines += "معرّف الشبكة: ${if (info.networkId >= 0) info.networkId else "غير متاح"}"
            lines += "BSSID: مخفي لحماية الخصوصية"
            lines += ""
            lines += "=== توصية أولية ==="
            lines += when {
                info.rssi <= -80 -> "الإشارة ضعيفة جداً. اقترب من الراوتر، وتجنب الجدران السميكة والعوائق."
                info.rssi <= -70 -> "الإشارة ضعيفة. جرّب مكاناً أقرب أو أعلى، وقارن النتائج قرب الراوتر."
                info.rssi <= -60 -> "الإشارة متوسطة إلى جيدة. قد يؤثر التداخل أو ازدحام القناة في الأداء."
                info.rssi > -60 -> "الإشارة قوية. إذا كان الإنترنت بطيئاً فافحص سرعة WAN والازدحام وDNS."
                else -> "تعذر تقييم الإشارة."
            }
            if (info.frequency in 2400..2500) {
                lines += "2.4 GHz: مدى تغطية أفضل عادةً، لكنه أكثر عرضة للازدحام."
            } else if (info.frequency in 4900..5900) {
                lines += "5 GHz: قد يعطي سرعة أعلى قرب الراوتر، لكن مداه عبر الجدران أقصر عادةً."
            }
        } catch (e: Exception) {
            lines += "تعذر قراءة Wi-Fi: ${e.javaClass.simpleName}: ${e.message}"
        }
        lines += ""
        lines += "ملاحظة: Android والشركة المصنّعة قد يحجبان بعض الحقول أو يعيدان قيماً قديمة. فحص الشبكات المجاورة والقنوات يحتاج صلاحية الموقع/الأجهزة القريبة، وقد يقيّد Android تكرار المسح."
        return lines.joinToString("\n")
    }

    private fun runSpeedTest(): String {
        val lines = mutableListOf<String>()
        lines += "=== اختبار سرعة الإنترنت ==="
        lines += "الخادم: Cloudflare speed.cloudflare.com"
        lines += "حجم التنزيل: 8 MB | حجم الرفع: 2 MB"
        val latencies = mutableListOf<Long>()
        var failed = 0
        repeat(9) {
            try {
                val start = System.nanoTime()
                val conn = (URL("https://www.google.com/generate_204").openConnection() as HttpURLConnection).apply {
                    requestMethod = "GET"
                    connectTimeout = 7000
                    readTimeout = 7000
                    useCaches = false
                }
                val code = conn.responseCode
                conn.disconnect()
                val ms = (System.nanoTime() - start) / 1_000_000
                if (code in 200..399) latencies += ms else failed++
            } catch (_: Exception) {
                failed++
            }
        }
        if (latencies.isNotEmpty()) {
            val stats = NetworkMetrics.fromSamples(latencies.map { it.toDouble() }, failed)
            lines += "وسيط زمن استجابة HTTPS: ${"%.1f".format(Locale.US, stats.median)} ms"
            lines += "متوسط زمن استجابة HTTPS: ${"%.1f".format(Locale.US, stats.mean)} ms"
            lines += "P95 لزمن الاستجابة: ${"%.1f".format(Locale.US, stats.p95)} ms"
            lines += "تذبذب العينات (متوسط فرق العينات المتتالية): ${"%.1f".format(Locale.US, stats.meanAbsoluteDelta)} ms"
            lines += "الانحراف المعياري: ${"%.1f".format(Locale.US, stats.standardDeviation)} ms"
            lines += "العينات الفاشلة: $failed من 9 — ليست قياساً لفقد حزم UDP/ICMP"
        } else {
            lines += "تعذر قياس زمن الاستجابة. تحقق من الاتصال أو VPN أو جدار الحماية."
        }

        try {
            val result = transfer(
                "https://speed.cloudflare.com/__down?bytes=$DOWNLOAD_BYTES",
                method = "GET",
                payload = null,
                readResponse = true
            )
            lines += "سرعة التنزيل التقريبية: ${formatMbps(result.first, result.second)}"
            lines += "البيانات المستلمة: ${result.first / 1_000_000.0} MB"
        } catch (e: Exception) {
            lines += "فشل اختبار التنزيل: ${e.javaClass.simpleName}: ${e.message}"
        }

        try {
            val payload = ByteArray(UPLOAD_BYTES) { (it * 31).toByte() }
            val result = transfer(
                "https://speed.cloudflare.com/__up",
                method = "POST",
                payload = payload,
                readResponse = false
            )
            lines += "سرعة الرفع التقريبية: ${formatMbps(result.first, result.second)}"
            lines += "البيانات المرسلة: ${result.first / 1_000_000.0} MB"
        } catch (e: Exception) {
            lines += "فشل اختبار الرفع: ${e.javaClass.simpleName}: ${e.message}"
        }

        lines += ""
        lines += "تنبيه دقة: هذه نتيجة اختبار واحد إلى خادم خارجي، وليست ضماناً لسرعة باقة المزود. تتأثر بالخادم والمسار والازدحام وقوة Wi-Fi والجهاز. أعد الاختبار مرتين أو ثلاثاً في أوقات مختلفة للمقارنة."
        lines += "الخصوصية: الاختبار يرسل طلبات HTTPS إلى Cloudflare وGoogle ولا يحتاج كلمة مرور الراوتر. لا يغيّر إعدادات الشبكة."
        return lines.joinToString("\n")
    }


    /**
     * Approximate loaded-latency test: HTTPS transaction latency is sampled
     * before and during simultaneous HTTP download/upload. This is not an
     * RFC 2544/RRUL test and does not measure ICMP/UDP packet delay or loss.
     */
    private fun runLoadedLatencyTest(): String {
        val lines = mutableListOf<String>()
        lines += "=== فحص زمن الاستجابة تحت الحمل ==="
        lines += "الخادم: Cloudflare speed.cloudflare.com + Google HTTPS probe"
        lines += "الحمل المتزامن: تنزيل 12 MB ورفع 3 MB تقريباً"
        lines += "القياس: 6 عينات HTTPS قبل الحمل و6 أثناءه"
        val baseline = measureHttpsSamples(6)
        if (baseline.isEmpty()) {
            return lines.joinToString("\n") + "\nتعذر أخذ عينات أساسية؛ تحقق من الاتصال ثم أعد المحاولة."
        }
        val download = loadExecutor.submit<Pair<Long, Double>> {
            transfer("https://speed.cloudflare.com/__down?bytes=12000000",
                method = "GET", payload = null, readResponse = true)
        }
        val upload = loadExecutor.submit<Pair<Long, Double>> {
            val payload = ByteArray(3_000_000) { (it * 17).toByte() }
            transfer("https://speed.cloudflare.com/__up",
                method = "POST", payload = payload, readResponse = false)
        }
        val loaded = measureHttpsSamples(6)
        val transferResults = mutableListOf<String>()
        try {
            val d = download.get()
            transferResults += "التنزيل أثناء الحمل: ${formatMbps(d.first, d.second)}"
        } catch (e: Exception) {
            transferResults += "تعذر إكمال حمل التنزيل: ${e.cause?.javaClass?.simpleName ?: e.javaClass.simpleName}"
        }
        try {
            val u = upload.get()
            transferResults += "الرفع أثناء الحمل: ${formatMbps(u.first, u.second)}"
        } catch (e: Exception) {
            transferResults += "تعذر إكمال حمل الرفع: ${e.cause?.javaClass?.simpleName ?: e.javaClass.simpleName}"
        }
        lines += ""
        lines += "=== النتائج ==="
        val baseStats = NetworkMetrics.fromSamples(baseline)
        lines += "وسيط الاستجابة قبل الحمل: ${"%.1f".format(Locale.US, baseStats.median)} ms"
        if (loaded.isNotEmpty()) {
            val loadedStats = NetworkMetrics.fromSamples(loaded)
            val assessment = NetworkMetrics.assessLoadedLatency(baseStats.p95, loadedStats.p95)
            lines += "P95 قبل الحمل: ${"%.1f".format(Locale.US, baseStats.p95)} ms"
            lines += "P95 أثناء الحمل: ${"%.1f".format(Locale.US, loadedStats.p95)} ms"
            lines += "زيادة P95 تحت الحمل: ${"%.1f".format(Locale.US, assessment.increaseMs)} ms"
            lines += "التقييم التقريبي: ${assessment.label}"
            lines += "العينات الناجحة: قبل ${baseline.size}/6، أثناء ${loaded.size}/6"
        } else {
            lines += "تعذر أخذ عينات أثناء الحمل؛ لا يمكن إصدار تقييم."
        }
        lines += ""
        lines += transferResults
        lines += ""
        lines += "مهم: هذا فحص تقريبي لزمن معاملات HTTPS وليس اختبار Bufferbloat معيارياً. لا يقيس UDP jitter أو packet loss، وقد تؤثر استجابة الخادم والمسار في النتيجة. للقياس المعياري نحتاج خادم اختبار مخصصاً يدعم تدفقات متعددة وقياساً زمنياً مستقلاً."
        return lines.joinToString("\n")
    }

    private fun measureHttpsSamples(count: Int): List<Double> {
        val samples = mutableListOf<Double>()
        repeat(count) {
            try {
                val start = System.nanoTime()
                val conn = (URL("https://www.google.com/generate_204").openConnection() as HttpURLConnection).apply {
                    requestMethod = "GET"
                    connectTimeout = 5000
                    readTimeout = 5000
                    useCaches = false
                }
                val code = conn.responseCode
                conn.disconnect()
                val elapsed = (System.nanoTime() - start) / 1_000_000.0
                if (code in 200..399) samples += elapsed
            } catch (_: Exception) {
                // Failed probes are excluded from latency percentiles.
            }
        }
        return samples
    }

    private fun transfer(
        address: String,
        method: String,
        payload: ByteArray?,
        readResponse: Boolean
    ): Pair<Long, Double> {
        val conn = (URL(address).openConnection() as HttpURLConnection).apply {
            requestMethod = method
            connectTimeout = 12000
            readTimeout = 20000
            useCaches = false
            if (payload != null) {
                doOutput = true
                setRequestProperty("Content-Type", "application/octet-stream")
                setFixedLengthStreamingMode(payload.size)
            }
        }
        val start = System.nanoTime()
        try {
            if (payload != null) {
                conn.outputStream.use { it.write(payload) }
            }
            val code = conn.responseCode
            if (code !in 200..299) throw IllegalStateException("HTTP $code")
            var bytes = payload?.size?.toLong() ?: 0L
            if (readResponse) {
                conn.inputStream.use { input ->
                    val buffer = ByteArray(64 * 1024)
                    while (true) {
                        val count = input.read(buffer)
                        if (count < 0) break
                        bytes += count
                    }
                }
            } else {
                conn.inputStream.use { stream ->
                    val discard = ByteArray(1024)
                    while (stream.read(discard) >= 0) {
                        // Consume the small server response before disconnecting.
                    }
                }
            }
            val seconds = (System.nanoTime() - start) / 1_000_000_000.0
            if (seconds <= 0.0 || bytes <= 0L) throw IllegalStateException("لم تصل بيانات قابلة للقياس")
            return bytes to seconds
        } finally {
            conn.disconnect()
        }
    }

    private fun formatMbps(bytes: Long, seconds: Double): String {
        val mbps = NetworkMetrics.throughputMbps(bytes, seconds)
        return "${"%.2f".format(Locale.US, mbps)} Mbps"
    }

    private fun signalLabel(rssi: Int): String = when {
        rssi <= -80 -> "ضعيفة جداً"
        rssi <= -70 -> "ضعيفة"
        rssi <= -60 -> "متوسطة"
        rssi <= -50 -> "جيدة"
        rssi > -50 -> "قوية جداً"
        else -> "غير معروفة"
    }

    private fun bandLabel(frequency: Int): String = when (frequency) {
        in 2400..2500 -> "نطاق 2.4 GHz"
        in 4900..5900 -> "نطاق 5 GHz"
        in 5925..7125 -> "نطاق 6 GHz (حسب دعم الجهاز والنظام)"
        else -> "غير معروف"
    }
}
