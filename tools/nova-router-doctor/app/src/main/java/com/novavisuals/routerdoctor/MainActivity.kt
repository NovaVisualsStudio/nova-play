package com.novavisuals.routerdoctor

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.text.method.ScrollingMovementMethod
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors
import javax.net.ssl.HttpsURLConnection

class MainActivity : Activity() {
    private lateinit var output: TextView
    private lateinit var runButton: Button
    private val worker = Executors.newSingleThreadExecutor()
    private val report = StringBuilder()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        buildUi()
        append("جاهز للفحص. اتصل بشبكة Wi-Fi المراد تشخيصها ثم اضغط بدء الفحص.")
        append("التطبيق لا يغيّر إعدادات الراوتر ولا يطلب كلمة المرور.")
    }

    private fun buildUi() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(28, 32, 28, 24)
            setBackgroundColor(0xFFF4F7FB.toInt())
        }
        val title = TextView(this).apply {
            text = "NOVA Router Doctor"
            textSize = 25f
            setTextColor(0xFF102A43.toInt())
            gravity = Gravity.CENTER
        }
        val subtitle = TextView(this).apply {
            text = "فحص Wi-Fi والراوتر والإنترنت"
            textSize = 16f
            gravity = Gravity.CENTER
            setPadding(0, 10, 0, 20)
        }
        runButton = Button(this).apply {
            text = "بدء الفحص الشامل"
            setOnClickListener { startDiagnostics() }
        }
        val copyButton = Button(this).apply {
            text = "نسخ التقرير"
            setOnClickListener {
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
                clipboard.setPrimaryClip(android.content.ClipData.newPlainText("NOVA Router Doctor report", report.toString()))
                Toast.makeText(this@MainActivity, "تم نسخ التقرير", Toast.LENGTH_SHORT).show()
            }
        }
        output = TextView(this).apply {
            textSize = 14f
            setTextColor(0xFF243B53.toInt())
            movementMethod = ScrollingMovementMethod()
            setTextIsSelectable(true)
            setPadding(14, 14, 14, 14)
            setBackgroundColor(0xFFFFFFFF.toInt())
        }
        root.addView(title)
        root.addView(subtitle)
        root.addView(runButton)
        root.addView(copyButton)
        root.addView(output, LinearLayout.LayoutParams(-1, 0, 1f).apply { topMargin = 14 })
        setContentView(root)
    }

    private fun append(line: String) {
        runOnUiThread {
            report.append(line).append("\n")
            output.text = report.toString()
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
                checkWifi()
                checkGateway()
                checkDns()
                checkHttps("https://www.google.com")
                checkHttps("https://www.cloudflare.com")
                append("\n=== خلاصة أولية ===")
                append("إذا كان اتصال البوابة المحلية ضعيفاً فافحص قرب الهاتف والتداخل اللاسلكي.")
                append("إذا نجح DNS وفشل HTTPS فقد توجد مشكلة اتصال أو TLS أو بوابة دخول.")
                append("إذا فشل DNS بينما يعمل الوصول إلى الإنترنت فقد تكون المشكلة من DNS.")
                append("هذه مؤشرات وليست حكماً نهائياً؛ قد تحجب بعض الشبكات اختبارات معينة.")
                append("\nلم يتم تغيير أي إعداد.")
            } catch (e: Exception) {
                append("تعذر إكمال بعض الاختبارات: ${e.message ?: "خطأ غير معروف"}")
            } finally {
                runOnUiThread { runButton.isEnabled = true }
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun checkWifi() {
        append("\n=== حالة Wi-Fi ===")
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork
        val caps = if (network != null) cm.getNetworkCapabilities(network) else null
        append("نوع الاتصال: " + when {
            caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true -> "Wi-Fi"
            caps?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true -> "بيانات الهاتف"
            else -> "غير معروف أو لا يوجد اتصال"
        })
        if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION), 41)
            append("لإظهار قوة الإشارة قد تحتاج إلى منح إذن الموقع وتفعيل خدمة الموقع في Android.")
            return
        }
        try {
            val wifi = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            val info = wifi.connectionInfo
            append("قوة الإشارة RSSI: ${info.rssi} dBm (تقريبية؛ -50 ممتازة، -67 جيدة، -75 ضعيفة)")
            append("سرعة الربط المعلنة: ${info.linkSpeed} Mbps")
            append("التردد: ${info.frequency} MHz")
            append("ملاحظة: بعض إصدارات Android تخفي هذه المعلومات أو تعرض قيماً غير متاحة.")
        } catch (e: Exception) {
            append("تعذر قراءة معلومات Wi-Fi: ${e.message}")
        }
    }

    private fun gatewayAddress(): String? {
        return try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val props = cm.getLinkProperties(cm.activeNetwork) ?: return null
            props.routes.firstOrNull { it.isDefaultRoute }?.gateway?.hostAddress
        } catch (_: Exception) { null }
    }

    private fun checkGateway() {
        append("\n=== اختبار الراوتر المحلي ===")
        val gateway = gatewayAddress()
        if (gateway == null) {
            append("لم يتمكن Android من تحديد البوابة الافتراضية.")
            return
        }
        append("عنوان البوابة: $gateway")
        try {
            val start = System.currentTimeMillis()
            Socket().use { it.connect(InetSocketAddress(gateway, 80), 1800) }
            append("منفذ HTTP للراوتر 80: متاح خلال ${System.currentTimeMillis() - start} ms")
        } catch (_: Exception) {
            append("منفذ 80 لا يستجيب أو مغلق؛ هذا لا يعني أن الراوتر معطل (قد يستخدم HTTPS أو يمنع الاتصال).")
        }
        try {
            val start = System.currentTimeMillis()
            val ok = InetAddress.getByName(gateway).isReachable(1800)
            append("اختبار الوصول للبوابة: ${if (ok) "استجابة" else "لا توجد استجابة مؤكدة"}، ${System.currentTimeMillis() - start} ms")
        } catch (e: Exception) {
            append("تعذر اختبار البوابة: ${e.message}")
        }
    }

    private fun checkDns() {
        append("\n=== اختبار DNS ===")
        listOf("google.com", "cloudflare.com").forEach { host ->
            try {
                val start = System.currentTimeMillis()
                val address = InetAddress.getByName(host)
                append("$host → ${address.hostAddress} — ${System.currentTimeMillis() - start} ms")
            } catch (e: Exception) {
                append("$host: فشل حل الاسم — ${e.message}")
            }
        }
    }

    private fun checkHttps(address: String) {
        append("\n=== HTTPS: $address ===")
        var connection: HttpsURLConnection? = null
        try {
            val start = System.currentTimeMillis()
            connection = (URL(address).openConnection() as HttpsURLConnection).apply {
                connectTimeout = 7000
                readTimeout = 7000
                requestMethod = "HEAD"
                instanceFollowRedirects = true
            }
            val code = connection.responseCode
            append("استجابة HTTP: $code — الزمن الكلي ${System.currentTimeMillis() - start} ms")
        } catch (e: Exception) {
            append("فشل HTTPS: ${e.javaClass.simpleName}: ${e.message}")
        } finally {
            connection?.disconnect()
        }
    }

    override fun onDestroy() {
        worker.shutdownNow()
        super.onDestroy()
    }
}
