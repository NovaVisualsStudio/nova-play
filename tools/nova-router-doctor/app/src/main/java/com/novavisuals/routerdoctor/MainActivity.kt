package com.novavisuals.routerdoctor

import android.Manifest
import android.app.Activity
import android.app.AlertDialog
import android.content.BroadcastReceiver
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.location.LocationManager
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
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
    private val wifiScanPermissionRequest = 7412
    private var wifiScanReceiverRegistered = false
    private val wifiScanReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == WifiManager.SCAN_RESULTS_AVAILABLE_ACTION) {
                val updated = intent.getBooleanExtra(WifiManager.EXTRA_RESULTS_UPDATED, false)
                unregisterWifiScanReceiver()
                showWifiScanResults(updated)
            }
        }
    }

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
            setSingleLine(true)
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
        val sourcesButton = Button(this).apply {
            text = "قواعد بيانات ومواقع دعم الشركات"
            setOnClickListener { showSupportSources() }
        }
        val networkLabButton = Button(this).apply {
            text = "مختبر الشبكة: Wi-Fi وقياس سرعة الإنترنت"
            setOnClickListener { NetworkLab.show(this@MainActivity) }
        }
        val wifiSurveyButton = Button(this).apply {
            text = "تحليل Wi-Fi المتقدم: الشبكات والقنوات"
            setOnClickListener { startWifiSurvey() }
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
        root.addView(sourcesButton)
        root.addView(networkLabButton)
        root.addView(wifiSurveyButton)
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
                val matched = lookupOpenWrtDatabase(query)
                if (!matched) {
                    append("\nلا توجد بطاقة محلية أو نتيجة OpenWrt مطابقة لهذا الموديل: $query")
                    append("افتح قاعدة OpenWrt أو صفحة دعم الشركة للبحث عن رقم الموديل وإصدار Hardware.")
                    startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://toh.openwrt.org/")))
                }
                append("تنبيه: قاعدة OpenWrt لا تشمل كل أجهزة GPON المقفلة من مزودي الخدمة، ولا تعني قابلية التفليش الآمن.")
            } else {
                append("\n=== بطاقة الموديل ===")
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


    private fun lookupOpenWrtDatabase(query: String): Boolean {
        return try {
            val json = assets.open("openwrt_devices.json").bufferedReader().use { it.readText() }
            val root = JSONObject(json)
            val devices = root.getJSONArray("devices")
            val q = query.lowercase(Locale.ROOT).replace(Regex("\\s+"), " ").trim()
            val matches = mutableListOf<JSONObject>()
            for (i in 0 until devices.length()) {
                val item = devices.getJSONObject(i)
                val brand = item.optString("brand")
                val model = item.optString("model")
                val combined = "$brand $model".lowercase(Locale.ROOT)
                if (combined.contains(q) || (q.length >= 4 && model.lowercase(Locale.ROOT).contains(q))) {
                    matches.add(item)
                    if (matches.size >= 5) break
                }
            }
            if (matches.isEmpty()) return false
            append("\nنتائج OpenWrt Table of Hardware — ${root.optInt("count")} جهاز في قاعدة المصدر")
            for (item in matches) {
                append("\n${item.optString("brand")} ${item.optString("model")} ${item.optString("version")}")
                val fields = listOf("cpu", "ram", "flash", "target", "2.4ghz", "5.0ghz", "device_type", "supported_current_release")
                for (key in fields) {
                    val value = item.optString(key)
                    if (value.isNotBlank()) append("$key: $value")
                }
                val page = item.optString("source_url")
                if (page.isNotBlank()) append("مرجع سجل الجهاز: $page")
            }
            append("المصدر: OpenWrt Wiki contributors — CC BY-SA 4.0 (راجع شروط المصدر).")
            true
        } catch (e: Exception) {
            append("قاعدة OpenWrt غير موجودة داخل هذه النسخة أو تعذر قراءتها: ${e.message}")
            false
        }
    }


    private fun showSupportSources() {
        try {
            val json = assets.open("router_models.json").bufferedReader().use { it.readText() }
            val root = JSONObject(json)
            val labels = mutableListOf<String>()
            val urls = mutableListOf<String>()
            val catalogues = root.optJSONArray("catalogues")
            if (catalogues != null) {
                for (i in 0 until catalogues.length()) {
                    val item = catalogues.getJSONObject(i)
                    labels.add("قاعدة بيانات: " + item.optString("name"))
                    urls.add(item.optString("url"))
                }
            }
            val vendors = root.optJSONArray("manufacturer_support")
            if (vendors != null) {
                for (i in 0 until vendors.length()) {
                    val item = vendors.getJSONObject(i)
                    labels.add("دعم الشركة: " + item.optString("name"))
                    urls.add(item.optString("url"))
                }
            }
            AlertDialog.Builder(this)
                .setTitle("مصادر الموديلات والدعم الرسمي")
                .setItems(labels.toTypedArray()) { _, which ->
                    if (which in urls.indices) {
                        startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(urls[which])))
                    }
                }
                .setNegativeButton("إغلاق", null)
                .show()
        } catch (e: Exception) {
            append("تعذر تحميل روابط الدعم: ${e.message}")
        }
    }

    private fun showRepairGuides() {
        try {
            val json = assets.open("repair_playbooks.json").bufferedReader().use { it.readText() }
            val items = JSONObject(json).getJSONArray("playbooks")
            append("\n========== أدلة التشخيص والإصلاح الآمن ==========")
            for (i in 0 until items.length()) {
                val item = items.getJSONObject(i)
                append("\n" + item.optString("title"))
                val signals = item.optJSONArray("signals")
                if (signals != null) for (j in 0 until signals.length()) append("علامة: " + signals.optString(j))
                val steps = item.optJSONArray("safe_steps")
                if (steps != null) for (j in 0 until steps.length()) append("خطوة: " + steps.optString(j))
                val avoid = item.optJSONArray("avoid")
                if (avoid != null) for (j in 0 until avoid.length()) append("تجنب: " + avoid.optString(j))
            }
            append("\nهذه إرشادات عامة؛ لا تنفذ إعدادات خاصة بالموديل إلا بعد مطابقة Hardware Version وFirmware.")
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

    private fun startWifiSurvey() {
        if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION), wifiScanPermissionRequest)
            return
        }
        val location = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val locationEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            location.isLocationEnabled
        } else {
            location.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                location.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }
        if (!locationEnabled) {
            AlertDialog.Builder(this)
                .setTitle("يلزم تفعيل الموقع")
                .setMessage("يتطلب Android إذن الموقع وخدمات الموقع لعرض نتائج مسح نقاط Wi-Fi القريبة. لا يجمع NOVA موقعك الجغرافي ولا يرسله إلى خادم.")
                .setPositiveButton("إعدادات الموقع") { _, _ ->
                    startActivity(Intent(android.provider.Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                }
                .setNegativeButton("إلغاء", null)
                .show()
            return
        }
        val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        if (!wifi.isWifiEnabled) {
            Toast.makeText(this, "فعّل Wi-Fi أولاً ثم أعد التحليل", Toast.LENGTH_LONG).show()
            return
        }
        try {
            val filter = IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)
            if (Build.VERSION.SDK_INT >= 33) {
                registerReceiver(wifiScanReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                registerReceiver(wifiScanReceiver, filter)
            }
            wifiScanReceiverRegistered = true
            @Suppress("DEPRECATION")
            val started = wifi.startScan()
            if (started) {
                Toast.makeText(this, "جارٍ مسح الشبكات القريبة… قد يقيّد Android تكرار المسح", Toast.LENGTH_LONG).show()
            } else {
                unregisterWifiScanReceiver()
                showWifiScanResults(false)
            }
        } catch (e: SecurityException) {
            unregisterWifiScanReceiver()
            Toast.makeText(this, "رفض Android صلاحية مسح Wi-Fi: ${e.message}", Toast.LENGTH_LONG).show()
        } catch (e: Exception) {
            unregisterWifiScanReceiver()
            Toast.makeText(this, "تعذر بدء مسح Wi-Fi: ${e.javaClass.simpleName}", Toast.LENGTH_LONG).show()
        }
    }

    private fun unregisterWifiScanReceiver() {
        if (wifiScanReceiverRegistered) {
            try { unregisterReceiver(wifiScanReceiver) } catch (_: Exception) { }
            wifiScanReceiverRegistered = false
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == wifiScanPermissionRequest) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                startWifiSurvey()
            } else {
                Toast.makeText(this, "لم تمنح صلاحية الموقع؛ لا يمكن لـ Android إظهار مسح الشبكات القريبة", Toast.LENGTH_LONG).show()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun showWifiScanResults(freshScan: Boolean) {
        try {
            val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val results = wifi.scanResults.orEmpty().sortedByDescending { it.level }
            if (results.isEmpty()) {
                AlertDialog.Builder(this)
                    .setTitle("تحليل Wi-Fi")
                    .setMessage("لم يعرض Android أي نقاط وصول. تحقق من تفعيل Wi-Fi والموقع، ثم حاول لاحقاً. قد تحد قيود النظام أو الشركة المصنّعة من النتائج.")
                    .setPositiveButton("حسناً", null)
                    .show()
                return
            }

            val nowMicros = SystemClock.elapsedRealtimeNanos() / 1000L
            val lines = mutableListOf<String>()
            lines += "عدد نقاط الوصول المرئية: ${results.size}"
            lines += if (freshScan) "حالة البيانات: نتيجة مسح حديث أبلغ عنها Android" else "حالة البيانات: قد تكون نتائج مخزنة مؤقتاً بسبب قيود المسح"
            lines += ""
            val observations = mutableListOf<WifiObservation>()
            results.forEachIndexed { index, ap ->
                val mapped = WifiChannelAnalyzer.channelForFrequencyMhz(ap.frequency)
                if (mapped?.first == "2.4 GHz") observations += WifiObservation(mapped.second, ap.level)
                val name = ap.SSID?.takeIf { it.isNotBlank() } ?: "شبكة مخفية"
                val channel = mapped?.second?.toString() ?: "غير معروف"
                val band = mapped?.first ?: "تردد غير معروف"
                val security = when {
                    ap.capabilities.contains("SAE", true) -> "WPA3"
                    ap.capabilities.contains("WPA2", true) -> "WPA2"
                    ap.capabilities.contains("WPA", true) -> "WPA"
                    ap.capabilities.contains("WEP", true) -> "WEP قديم"
                    else -> "مفتوحة/غير محددة"
                }
                val ageSeconds = ((nowMicros - ap.timestamp).coerceAtLeast(0L) / 1_000_000L)
                lines += "${index + 1}. $name"
                lines += "   ${ap.level} dBm (${WifiChannelAnalyzer.signalQualityLabel(ap.level)}) | $band | قناة $channel | ${ap.frequency} MHz"
                lines += "   الحماية: $security | عمر سجل المسح: ${ageSeconds}s"
            }
            val ranked = WifiChannelAnalyzer.rank24GhzChannels(observations)
            if (ranked.isNotEmpty() && observations.isNotEmpty()) {
                lines += ""
                lines += "=== تقدير ضغط القنوات 2.4 GHz ==="
                ranked.forEach { score ->
                    val scoreText = String.format(Locale.US, "%.2f", score.score)
                    lines += "القناة ${score.channel}: نقاط قريبة متداخلة تقريباً ${score.visibleAccessPoints} | مؤشر الضغط $scoreText"
                }
                lines += "اقتراح أولي: جرّب القناة ${ranked.first().channel} إذا كان الراوتر يسمح بذلك، ثم قارن الأداء."
            } else {
                lines += ""
                lines += "لم تظهر نقاط وصول 2.4 GHz كافية لتقديم مقارنة للقنوات."
            }
            lines += ""
            lines += "حدود القياس: عدد الشبكات وقوة RSSI لا يقيسان إشغال الهواء (airtime) أو التداخل الطيفي الفعلي. النتيجة تقدير من إعلانات نقاط الوصول التي استطاع الهاتف استقبالها فقط."
            lines += "قد لا يعرض Android كل الشبكات، وقد تكون النتائج قديمة. يفرض النظام حدوداً على تكرار المسح، وقد تتغير الدقة حسب إصدار Android والشركة المصنّعة."
            lines += "الخصوصية: لا نعرض BSSID أو عنوان MAC ولا نرسل أسماء الشبكات إلى أي خادم."
            val textView = TextView(this).apply {
                text = lines.joinToString("\n")
                textSize = 14f
                setTextIsSelectable(true)
                setPadding(28, 20, 28, 20)
            }
            AlertDialog.Builder(this)
                .setTitle("تقرير ذكاء Wi-Fi")
                .setView(ScrollView(this).apply { addView(textView) })
                .setPositiveButton("إغلاق", null)
                .show()
        } catch (e: SecurityException) {
            Toast.makeText(this, "Android منع قراءة نتائج المسح: ${e.message}", Toast.LENGTH_LONG).show()
        } catch (e: Exception) {
            Toast.makeText(this, "فشل تحليل نتائج Wi-Fi: ${e.javaClass.simpleName}", Toast.LENGTH_LONG).show()
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
        unregisterWifiScanReceiver()
        worker.shutdownNow()
        super.onDestroy()
    }
}
