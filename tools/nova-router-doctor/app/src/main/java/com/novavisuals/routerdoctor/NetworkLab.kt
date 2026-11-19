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
import kotlin.math.sqrt

/**
 * Read-only network lab. Speed measurements use Cloudflare's public speed-test
 * endpoints; no router credentials or configuration are accessed.
 */
object NetworkLab {
    private const val DOWNLOAD_BYTES = 8_000_000
    private const val UPLOAD_BYTES = 2_000_000
    private val executor = Executors.newSingleThreadExecutor()
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
        val closeButton = Button(activity).apply {
            text = "إغلاق"
        }
        root.addView(wifiButton)
        root.addView(speedButton)
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
        closeButton.setOnClickListener { dialog.dismiss() }
        wifiButton.setOnClickListener {
            wifiButton.isEnabled = false
            output.text = "جارٍ تحليل اتصال Wi-Fi..."
            executor.execute {
                val result = inspectWifi(activity)
                main.post {
                    output.text = result
                    wifiButton.isEnabled = true
                }
            }
        }
        speedButton.setOnClickListener {
            speedButton.isEnabled = false
            wifiButton.isEnabled = false
            output.text = "جارٍ قياس زمن الاستجابة والتنزيل والرفع. أبقِ التطبيق مفتوحاً ولا تنتقل بين Wi-Fi وبيانات الهاتف..."
            executor.execute {
                val result = runSpeedTest()
                main.post {
                    output.text = result
                    speedButton.isEnabled = true
                    wifiButton.isEnabled = true
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
        repeat(5) { index ->
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
            val avg = latencies.average()
            val jitter = if (latencies.size > 1) {
                sqrt(latencies.map { (it - avg) * (it - avg) }.average())
            } else 0.0
            lines += "زمن استجابة HTTPS المتوسط: ${"%.1f".format(Locale.US, avg)} ms"
            lines += "تذبذب الاستجابة (انحراف معياري): ${"%.1f".format(Locale.US, jitter)} ms"
            lines += "عينات فاشلة: $failed من 5 — ليست قياساً كاملاً لفقد حزم ICMP"
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
                conn.inputStream.use { it.copyTo(java.io.OutputStream.nullOutputStream()) }
            }
            val seconds = (System.nanoTime() - start) / 1_000_000_000.0
            if (seconds <= 0.0 || bytes <= 0L) throw IllegalStateException("لم تصل بيانات قابلة للقياس")
            return bytes to seconds
        } finally {
            conn.disconnect()
        }
    }

    private fun formatMbps(bytes: Long, seconds: Double): String {
        val mbps = bytes * 8.0 / seconds / 1_000_000.0
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
