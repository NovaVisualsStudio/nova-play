package com.novavisuals.routerdoctor

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
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
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import java.net.HttpURLConnection
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors
import javax.net.ssl.HttpsURLConnection
import org.json.JSONObject

class MainActivity : Activity() {
    private lateinit var output: TextView
    private lateinit var runButton: Button
    private lateinit var modelInput: EditText
    private val worker = Executors.newSingleThreadExecutor()
    private val report = StringBuilder()
    @Volatile private var gateway: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        buildUi()
        append("جاهز. اتصل بشبكة Wi-Fi التي تريد فحصها ثم ابدأ التشخيص.")
        append("يدعم الفحص العام راوترات Nokia وHuawei وZTE وTP-Link وD-Link وغيرها.")
        append("لا يطلب التطبيق كلمات المرور ولا يغيّر إعدادات الراوتر تلقائياً.")
    }

    private fun buildUi() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(24, 28, 24, 20)
            setBackgroundColor(0xFFF3F6FA.toInt())
        }
        val title = TextView(this).apply {
            text = "NOVA Router Doctor"
            textSize = 25f
            setTextColor(0xFF102A43.toInt())
            gravity = Gravity.CENTER
        }
        val subtitle = TextView(this).apply {
            text = "تشخيص Wi-Fi والراوتر والإنترنت وإرشادات الإصلاح"
            textSize = 14f
            gravity = Gravity.CENTER
            setTextColor(0xFF486581.toInt())
            setPadding(0, 8, 0, 14)
        }
        modelInput = EditText(this).apply {
            hint = "اكتب الشركة والموديل، مثال: Nokia G-2426G-A"
            textSize = 14f
            singleLine = true
            setPadding(14, 8, 14, 8)
            setBackgroundColor(0xFFFFFFFF.toInt())
        }
        val modelButton = Button(this).apply {
            text = "ابحث في قاعدة الموديلات"
            setOnClickListener { lookupModel() }
        }
        val guidesButton = Button(this).apply {
            text = "دليل أعطال وإصلاح Wi-Fi والإنترنت"
            setOnClickListener { showRepairGuides() }
        }
        runButton = Button(this).apply {
            text = "ابدأ الفحص الشامل"
            setOnClickListener { startDiagnostics() }
        }
        val adminButton = Button(this).apply {
            text = "فتح صفحة الراوتر"
            setOnClickListener { openRouterAdmin() }
        }
        val copyButton = Button(this).apply {
            text = "نسخ تقرير الفحص"
            setOnClickListener {
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                clipboard.setPrimaryClip(ClipData.newPlainText("NOVA Router Doctor", report.toString()))
                Toast.makeText(this@MainActivity, "تم نسخ التقرير", Toast.LENGTH_SHORT).show()
            }
        }
        val termuxButton = Button(this).apply {
            text = "عرض أوامر Termux المتقدمة"
            setOnClickListener {
                append("\n\n=== أوامر Termux ===")
                append("pkg update -y")
                append("pkg install -y iproute2 iputils dnsutils curl traceroute")
                append("mkdir -p ~/router-check && cd ~/router-check")
                append("curl -L https://raw.githubusercontent.com/NovaVisualsStudio/nova-play/main/tools/nokia-router-diagnostic/advanced-check.sh -o advanced-check.sh")
                append("chmod +x advanced-check.sh && bash advanced-check.sh")
                append("التقرير سيُحفظ داخل ~/router-check/")
            }
        }
        output = TextView(this).apply {
            textSize = 14f
            setTextColor(0xFF243B53.toInt())
            movementMethod = ScrollingMovementMethod()
            setTextIsSelectable(true)
            setPadding(16, 16, 16, 16)
            setBackgroundColor(0xFFFFFFFF.toInt())
        }
        root.addView(title)
        root.addView(subtitle)
        root.addView(modelInput)
        root.addView(modelButton)
        root.addView(guidesButton)
        root.addView(runButton)
        root.addView(adminButton)
        root.addView(copyButton)
        root.addView(termuxButton)
        root.addView(ScrollView(this).apply {
            addView(output)
            layoutParams = LinearLayout.LayoutParams(-1, 0, 1f).apply { topMargin = 12 }
        })
        setContentView(root)
    }

    private fun append(line: String) {
        runOnUiThread {
            report.append(line).append("\n")
            output.text = report.toString()
        }
    }


    private fun lookupModel() {
        val query = modelInput.text.toString().trim()
        if (query.isEmpty()) {
            Toast.makeText(this, "اكتب اسم الشركة والموديل أولاً", Toast.LENGTH_SHORT).show()
            return
        }
        try {
            val json = assets.open("router_models.json").bufferedReader().use { it.readText() }
            val devices = JSONObject(json).getJSONArray("devices")
            val q = query.lowercase(Locale.ROOT)
            var found: JSONObject? = null
            for (i in 0 until devices.length()) {
                val item = devices.getJSONObject(i)
                val terms = mutableListOf(item.optString("manufacturer"), item.optString("model"))
                val aliases = item.optJSONArray("aliases")
                if (aliases != null) for (j in 0 until aliases.length()) terms.add(aliases.optString(j))
                if (terms.any { it.lowercase(Locale.ROOT).contains(q) || q.contains(it.lowercase(Locale.ROOT)) && it.isNotBlank() }) {
                    found = item
                    break
                }
            }
            if (found == null) {
                append("\\nلا توجد بطاقة محلية موثقة لهذا الموديل بعد: $query")
                append("يمكن فتح قاعدة OpenWrt العامة أو صفحة دعم الشركة للبحث عن رقم الموديل وإصدار Hardware.")
                append("قاعدة OpenWrt لا تشمل كل أجهزة GPON المقفلة من مزودي الخدمة.")
                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://toh.openwrt.org/")))
            } else {
                append("\\n=== بطاقة الموديل ===")
                append("الشركة: " + found.optString("manufacturer"))
                append("الموديل: " + found.optString("model"))
                append("نوع الجهاز: " + found.optString("device_type"))
                val specs = found.optJSONObject("verified_specs")
                if (specs != null) {
                    val keys = specs.keys()
                    while (keys.hasNext()) {
                        val key = keys.next()
                        append("$key: " + specs.optString(key))
                    }
                }
                val caveats = found.optJSONArray("caveats")
                if (caveats != null) for (i in 0 until caveats.length()) append("تنبيه: " + caveats.optString(i))
                val source = found.optString("support_url")
                if (source.isNotBlank()) append("مرجع الشركة: $source")
                val guide = found.optString("product_guide_url")
                if (guide.isNotBlank()) append("دليل المنتج: $guide")
            }
        } catch (e: Exception) {
            append("تعذر قراءة قاعدة الموديلات: ${e.message}")
        }
    }

    private fun showRepairGuides() {
        try {
            val json = assets.open("repair_playbooks.json").bufferedReader().use { it.readText() }
            val items = JSONObject(json).getJSONArray("playbooks")
            append("\\n========== أدلة التشخيص والإصلاح الآمن ==========")
            for (i in 0 until items.length()) {
                val item = items.getJSONObject(i)
                append("\\n" + item.optString("title"))
                val signals = item.optJSONArray("signals")
                if (signals != null) for (j in 0 until signals.length()) append("علامة: " + signals.optString(j))
                val steps = item.optJSONArray("safe_steps")
                if (steps != null) for (j in 0 until steps.length()) append("خطوة: " + steps.optString(j))
                val avoid = item.optJSONArray("avoid")
                if (avoid != null) for (j in 0 until avoid.length()) append("تجنب: " + avoid.optString(j))
            }
            append("\\nهذه إرشادات عامة؛ لا تنفذ إعدادات خاصة بالموديل إلا بعد مطابقة Hardware Version وFirmware.")
        } catch (e: Exception) {
            append("تعذر تحميل أدلة الإصلاح: ${e.message}")
        }
    }

    private fun openRouterAdmin() {
        val address = gateway ?: gatewayAddress()
        if (address.isNullOrBlank()) {
            Toast.makeText(this, "تعذر تحديد عنوان الراوتر. اتصل بشبكة Wi-Fi أولاً.", Toast.LENGTH_LONG).show()
            return
        }
        gateway = address
        try {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("http://$address")))
        } catch (_: Exception) {
            startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://$address")))
        }
    }

    private fun startDiagnostics() {
        report.clear()
        output.text = ""
        runButton.isEnabled = false
        append("NOVA ROUTER DOCTOR — تقرير تشخيصي")
        append("التاريخ: " + SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date()))
        worker.execute {
            try {
                val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                val network = cm.activeNetwork
                val caps = if (network != null) cm.getNetworkCapabilities(network) else null
                val wifi = caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
                append("\n1) حالة الاتصال")
                append("Wi-Fi: " + if (wifi) "متصل" else "غير متصل أو الاتصال عبر بيانات الهاتف")
                append("الاتصال بالإنترنت بحسب Android: " + if (caps?.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED) == true) "متحقق" else "غير مؤكد")
                gateway = gatewayAddress()
                append("بوابة الراوتر: " + (gateway ?: "غير متاحة"))

                var rssi = -127
                var link = -1
                var frequency = -1
                try {
                    @Suppress("DEPRECATION")
                    val info = (applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager).connectionInfo
                    rssi = info.rssi
                    link = info.linkSpeed
                    frequency = info.frequency
                    append("قوة Wi-Fi: $rssi dBm")
                    append("سرعة الربط النظرية: $link Mbps")
                    append("تردد Wi-Fi: $frequency MHz")
                } catch (e: Exception) {
                    append("معلومات الإشارة غير متاحة على إصدار Android هذا: ${e.message}")
                }

                append("\n2) الوصول إلى الراوتر")
                val gw = gateway
                val gw80 = gw != null && testTcp(gw, 80, 1800)
                val gw443 = gw != null && testTcp(gw, 443, 1800)
                append("منفذ الإدارة HTTP/80: " + if (gw80) "يستجيب" else "لا يستجيب أو مغلق")
                append("منفذ الإدارة HTTPS/443: " + if (gw443) "يستجيب" else "لا يستجيب أو مغلق")
                append("تنبيه: إغلاق المنفذين لا يثبت تعطل الراوتر؛ قد يستخدم منفذاً آخر أو يمنع الاختبار.")

                append("\n3) اختبار الإنترنت عبر IP")
                val cloud = testTcp("1.1.1.1", 443, 3000)
                val google = testTcp("8.8.8.8", 443, 3000)
                append("Cloudflare 1.1.1.1:443: " + if (cloud) "ناجح" else "فاشل")
                append("Google 8.8.8.8:443: " + if (google) "ناجح" else "فاشل")

                append("\n4) اختبار DNS")
                val dnsGoogle = dnsTest("google.com")
                val dnsCloudflare = dnsTest("cloudflare.com")
                append("google.com: " + if (dnsGoogle) "ناجح" else "فاشل")
                append("cloudflare.com: " + if (dnsCloudflare) "ناجح" else "فاشل")

                append("\n5) اختبار HTTPS وزمن الاستجابة")
                val httpsGoogle = httpsTest("https://www.google.com")
                val httpsCloudflare = httpsTest("https://www.cloudflare.com")
                append("Google HTTPS: " + httpsGoogle)
                append("Cloudflare HTTPS: " + httpsCloudflare)

                append("\n6) النتيجة والإصلاح المقترح")
                when {
                    !wifi -> {
                        append("التشخيص: الهاتف ليس متصلاً عبر Wi-Fi.")
                        append("الإجراء: اتصل بشبكة الراوتر الصحيحة ثم أعد الفحص.")
                    }
                    gw == null -> {
                        append("التشخيص: لم يتمكن Android من تحديد البوابة المحلية.")
                        append("الإجراء: أوقف VPN مؤقتاً إن كان يعمل، أعد الاتصال بالـ Wi-Fi، ثم أعد الفحص.")
                    }
                    !gw80 && !gw443 -> {
                        append("التشخيص: لم تؤكد اختبارات منافذ الإدارة الوصول إلى واجهة الراوتر.")
                        append("الإجراء: اقترب من الراوتر، أعد تشغيل Wi-Fi في الهاتف، ثم تحقق من عنوان البوابة. قد تكون واجهة الإدارة على منفذ مختلف.")
                    }
                    !cloud && !google -> {
                        append("التشخيص: الاتصال المحلي ظاهر لكن الاتصال الخارجي فشل.")
                        append("الإجراء: افحص لمبات Internet/WAN وPON/LOS، ثم أعد تشغيل الراوتر مرة واحدة بالطريقة المعتادة. إذا استمر العطل تواصل مع المزود.")
                        append("لا تغيّر إعدادات GPON أو VLAN أو WAN؛ قد يؤدي ذلك إلى قطع الخدمة.")
                    }
                    !dnsGoogle && !dnsCloudflare -> {
                        append("التشخيص: فشل حل أسماء النطاقات مع احتمال وجود اتصال IP.")
                        append("الإجراء الآمن: اختبر DNS خاصاً موثوقاً على الهاتف فقط، ثم أعد الفحص. لا تغيّر DNS الراوتر قبل التأكد.")
                    }
                    httpsGoogle.startsWith("فشل") && httpsCloudflare.startsWith("فشل") -> {
                        append("التشخيص: DNS قد يعمل لكن HTTPS فشل.")
                        append("الإجراء: تحقق من التاريخ والوقت، أوقف VPN/Proxy مؤقتاً، وافحص وجود صفحة تسجيل دخول للشبكة.")
                    }
                    rssi != -127 && rssi < -75 -> {
                        append("التشخيص: إشارة Wi-Fi ضعيفة.")
                        append("الإجراء: اقترب من الراوتر، ارفع مكانه، أبعده عن الأجهزة المعدنية ومصادر التداخل، ثم أعد الفحص.")
                    }
                    else -> {
                        append("التشخيص: الاختبارات الأساسية ناجحة.")
                        append("إذا استمر البطء، قارن السرعة قرب الراوتر وبعيداً عنه، وجرّب تقليل ازدحام الأجهزة والقناة اللاسلكية.")
                    }
                }
                append("\nالنطاق: الفحوصات العامة تعمل مع مختلف العلامات التجارية. فحوص GPON/ONT وطرق الإصلاح الدقيقة تتطلب موديل الراوتر وإصدار البرنامج الثابت.")
                append("السلامة: لم يتم تسجيل الدخول إلى الراوتر ولم يتم تغيير أي إعداد.")
            } catch (e: Exception) {
                append("تعذر إكمال بعض الاختبارات: ${e.javaClass.simpleName}: ${e.message}")
            } finally {
                runOnUiThread { runButton.isEnabled = true }
            }
        }
    }

    private fun gatewayAddress(): String? {
        return try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val active = cm.activeNetwork ?: return null
            val props = cm.getLinkProperties(active) ?: return null
            props.routes.firstOrNull { it.isDefaultRoute }?.gateway?.hostAddress
        } catch (_: Exception) { null }
    }

    private fun testTcp(host: String, port: Int, timeout: Int): Boolean {
        return try {
            Socket().use { it.connect(InetSocketAddress(host, port), timeout) }
            true
        } catch (_: Exception) { false }
    }

    private fun dnsTest(host: String): Boolean {
        return try { InetAddress.getAllByName(host).isNotEmpty() } catch (_: Exception) { false }
    }

    private fun httpsTest(address: String): String {
        var connection: HttpsURLConnection? = null
        val start = System.currentTimeMillis()
        return try {
            connection = (URL(address).openConnection() as HttpsURLConnection).apply {
                connectTimeout = 6000
                readTimeout = 6000
                requestMethod = "HEAD"
                instanceFollowRedirects = true
            }
            val code = connection.responseCode
            "ناجح — HTTP $code، ${System.currentTimeMillis() - start} ms"
        } catch (e: Exception) {
            "فشل — ${e.javaClass.simpleName}: ${e.message}"
        } finally {
            connection?.disconnect()
        }
    }

    override fun onDestroy() {
        worker.shutdownNow()
        super.onDestroy()
    }
}
