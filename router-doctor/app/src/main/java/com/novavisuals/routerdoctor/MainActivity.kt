package com.novavisuals.routerdoctor

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Bundle
import android.text.method.ScrollingMovementMethod
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import java.net.HttpURLConnection
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors

class MainActivity : Activity() {
    private val executor = Executors.newSingleThreadExecutor()
    private lateinit var output: TextView
    private lateinit var gateway: String

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        gateway = getGateway()
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(28, 30, 28, 24)
            setBackgroundColor(0xFFF5F7FB.toInt())
        }
        val title = TextView(this).apply {
            text = "NOVA Router Doctor"
            textSize = 25f
            setTextColor(0xFF14233B.toInt())
            gravity = Gravity.CENTER
        }
        val subtitle = TextView(this).apply {
            text = "فحص Wi-Fi والراوتر والإنترنت • يعمل مع مختلف العلامات التجارية"
            textSize = 14f
            gravity = Gravity.CENTER
            setTextColor(0xFF53627A.toInt())
            setPadding(0, 10, 0, 20)
        }
        val scan = Button(this).apply {
            text = "ابدأ الفحص الشامل"
            setOnClickListener { runDiagnostics() }
        }
        val admin = Button(this).apply {
            text = "فتح صفحة إعدادات الراوتر"
            setOnClickListener {
                if (gateway.isNotBlank()) {
                    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("http://$gateway")))
                } else append("\nلم أتمكن من تحديد عنوان الراوتر تلقائياً.")
            }
        }
        val termux = Button(this).apply {
            text = "أوامر الفحص المتقدم في Termux"
            setOnClickListener {
                append("\n\nأوامر Termux:\npkg update -y && pkg install -y iproute2 iputils dnsutils curl traceroute\ncurl -L https://raw.githubusercontent.com/NovaVisualsStudio/nova-play/main/tools/nokia-router-diagnostic/advanced-check.sh -o advanced-check.sh\nchmod +x advanced-check.sh && bash advanced-check.sh\n\nالتقرير: ~/router-check/")
            }
        }
        output = TextView(this).apply {
            textSize = 14f
            setTextColor(0xFF17243A.toInt())
            movementMethod = ScrollingMovementMethod()
            setTextIsSelectable(true)
            text = "جاهز للفحص. اتصل بشبكة Wi-Fi التي تريد تشخيصها ثم اضغط «ابدأ الفحص الشامل».\n\nهذا التطبيق لا يطلب كلمة مرور الراوتر ولا يغيّر إعداداته تلقائياً."
            setPadding(18, 18, 18, 18)
            setBackgroundColor(0xFFFFFFFF.toInt())
        }
        root.addView(title)
        root.addView(subtitle)
        root.addView(scan)
        root.addView(admin)
        root.addView(termux)
        root.addView(ScrollView(this).apply {
            addView(output)
            layoutParams = LinearLayout.LayoutParams(-1, 0, 1f).apply { topMargin = 16 }
        })
        setContentView(root)
    }

    private fun append(s: String) {
        runOnUiThread { output.append("\n$s") }
    }

    private fun getGateway(): String {
        return try {
            val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val raw = wm.dhcpInfo.gateway
            if (raw == 0) "" else listOf(raw and 255, raw shr 8 and 255, raw shr 16 and 255, raw shr 24 and 255).joinToString(".")
        } catch (_: Exception) { "" }
    }

    private fun runDiagnostics() {
        output.text = "جارٍ تنفيذ الفحص...\nلا تغلق التطبيق."
        executor.execute {
            val report = StringBuilder()
            fun line(s: String) { report.append(s).append("\n"); runOnUiThread { output.text = report.toString() } }
            line("NOVA ROUTER DOCTOR — تقرير تشخيص")
            line("التاريخ: " + SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date()))
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = cm.activeNetwork
            val caps = if (network != null) cm.getNetworkCapabilities(network) else null
            val wifiConnected = caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
            line("\n1) الاتصال المحلي")
            line("Wi-Fi متصل: " + if (wifiConnected) "نعم" else "لا / غير مكتشف")
            gateway = getGateway()
            line("عنوان بوابة الراوتر: " + if (gateway.isBlank()) "غير متاح" else gateway)
            try {
                val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                @Suppress("DEPRECATION")
                val info = wm.connectionInfo
                line("قوة الإشارة: ${info.rssi} dBm (كلما اقتربت من -30 كانت أقوى؛ أقل من -75 غالباً ضعيفة)")
                line("سرعة الربط المعلنة: ${info.linkSpeed} Mbps")
                line("التردد: ${info.frequency} MHz")
            } catch (e: Exception) { line("تعذر قراءة معلومات Wi-Fi: ${e.message}") }

            line("\n2) اختبار الوصول إلى الراوتر")
            val gwOk = if (gateway.isNotBlank()) testTcp(gateway, 80, 1800) || testTcp(gateway, 443, 1800) else false
            line("منفذ إدارة الراوتر HTTP/HTTPS يستجيب: " + if (gwOk) "نعم" else "لا أو محجوب")
            line("\n3) اختبار الإنترنت")
            val cloud = testTcp("1.1.1.1", 443, 3000)
            val google = testTcp("8.8.8.8", 443, 3000)
            line("اتصال TCP إلى Cloudflare 1.1.1.1:443: " + if (cloud) "ناجح" else "فاشل")
            line("اتصال TCP إلى Google 8.8.8.8:443: " + if (google) "ناجح" else "فاشل")

            line("\n4) اختبار DNS")
            val dnsOk = try { InetAddress.getAllByName("example.com").isNotEmpty() } catch (_: Exception) { false }
            line("حل اسم example.com: " + if (dnsOk) "ناجح" else "فاشل")

            line("\n5) اختبار HTTPS")
            val httpsCode = try {
                val c = (URL("https://www.cloudflare.com").openConnection() as HttpURLConnection)
                c.connectTimeout = 4500
                c.readTimeout = 4500
                c.requestMethod = "HEAD"
                c.instanceFollowRedirects = true
                val code = c.responseCode
                c.disconnect()
                code
            } catch (_: Exception) { -1 }
            line("استجابة HTTPS: " + if (httpsCode in 200..499) "ناجحة (HTTP $httpsCode)" else "فاشلة/انتهت المهلة")

            line("\n6) التشخيص الأولي والإرشادات")
            when {
                !wifiConnected -> line("الاحتمال الأقوى: الهاتف غير متصل عبر Wi-Fi. أعد الاتصال بالشبكة وتأكد من تشغيل WLAN في الراوتر.")
                gateway.isBlank() || !gwOk -> line("تعذر الوصول إلى بوابة الراوتر. افحص قوة الإشارة، اقترب من الراوتر، ثم أعد تشغيل Wi-Fi في الهاتف. قد تكون منافذ الإدارة محجوبة؛ هذه النتيجة ليست دليلاً قاطعاً على عطل الراوتر.")
                !cloud && !google -> line("الاتصال المحلي موجود لكن الوصول إلى الإنترنت فشل. الاحتمال: WAN/مزود الخدمة أو انقطاع الإنترنت. افحص لمبات PON/LOS/Internet ولا تغيّر إعدادات GPON.")
                !dnsOk -> line("الإنترنت عبر IP قد يعمل لكن DNS لا يحل الأسماء. جرّب DNS موثوقاً من إعدادات الهاتف أولاً، ولا تغيّر DNS الراوتر قبل التأكد.")
                httpsCode == -1 -> line("DNS متاح لكن HTTPS فشل. تحقق من الوقت والتاريخ، بوابة تسجيل الدخول، أو قيود الشبكة.")
                else -> line("الاختبارات الأساسية ناجحة. إذا بقي البطء، قارن السرعة قرب الراوتر وبعيداً عنه وافحص ازدحام القناة وعدد الأجهزة.")
            }
            line("\nمهم: الفحص لا يغيّر إعدادات الراوتر ولا يسجّل الدخول إليه. النتائج أولية وقد تتأثر بحجب المنافذ أو سياسات الشبكة.")
            line("\nأجهزة/علامات مدعومة: Nokia وHuawei وZTE وTP-Link وD-Link وغيرها في اختبارات الشبكة العامة. خصائص GPON وإصلاحات كل موديل تحتاج بياناته ودليله.")
        }
    }

    private fun testTcp(host: String, port: Int, timeout: Int): Boolean {
        return try {
            Socket().use { it.connect(InetSocketAddress(host, port), timeout) }
            true
        } catch (_: Exception) { false }
    }

    override fun onDestroy() {
        executor.shutdownNow()
        super.onDestroy()
    }
}
