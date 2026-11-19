package com.novavisuals.routerdoctor

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import java.net.Inet4Address
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

data class LanDeviceResult(
    val address: String,
    val openPorts: List<Int>,
    val isGateway: Boolean
)

/** Pure planning helpers, bounded to private IPv4 /24-/30 ranges. */
object LanDiscoveryCore {
    private const val IPV4_MAX = 0xFFFF_FFFFL

    fun targetHosts(localIpv4: String, prefixLength: Int): List<String> {
        require(prefixLength in 24..30) {
            "LAN scan is limited to IPv4 prefixes /24 through /30"
        }
        val local = parseIpv4(localIpv4)
        require(isPrivateIpv4(local)) { "Only RFC1918 private IPv4 networks are supported" }
        val hostBits = 32 - prefixLength
        val mask = (IPV4_MAX shl hostBits) and IPV4_MAX
        val network = local and mask
        val broadcast = network or (mask xor IPV4_MAX)
        require(local > network && local < broadcast) {
            "Local address is not a usable host address for this subnet"
        }
        return (network + 1 until broadcast)
            .filter { it != local }
            .map(::formatIpv4)
    }

    fun networkCidr(localIpv4: String, prefixLength: Int): String {
        require(prefixLength in 24..30)
        val local = parseIpv4(localIpv4)
        require(isPrivateIpv4(local))
        val hostBits = 32 - prefixLength
        val mask = (IPV4_MAX shl hostBits) and IPV4_MAX
        return formatIpv4(local and mask) + "/" + prefixLength
    }

    fun probableRole(openPorts: Set<Int>, isGateway: Boolean): String {
        if (isGateway) return "الراوتر / البوابة الافتراضية"
        return when {
            9100 in openPorts || 631 in openPorts -> "طابعة أو خدمة طباعة محتملة"
            554 in openPorts -> "كاميرا أو جهاز بث فيديو محتمل"
            445 in openPorts -> "مشاركة ملفات أو NAS أو Windows محتمل"
            22 in openPorts -> "جهاز شبكة أو Linux بخدمة SSH محتملة"
            80 in openPorts || 443 in openPorts || 8080 in openPorts ->
                "واجهة ويب أو لوحة إدارة محتملة"
            else -> "جهاز بخدمة TCP ظاهرة"
        }
    }

    private fun parseIpv4(value: String): Long {
        val parts = value.split(".")
        require(parts.size == 4) { "A valid IPv4 address is required" }
        return parts.fold(0L) { acc, part ->
            val octet = part.toIntOrNull()
            require(octet != null && octet in 0..255) { "Invalid IPv4 address" }
            (acc shl 8) or octet.toLong()
        }
    }

    private fun isPrivateIpv4(value: Long): Boolean {
        val first = ((value ushr 24) and 0xFF).toInt()
        val second = ((value ushr 16) and 0xFF).toInt()
        return first == 10 ||
            (first == 172 && second in 16..31) ||
            (first == 192 && second == 168)
    }

    private fun formatIpv4(value: Long): String = listOf(
        (value ushr 24) and 0xFF,
        (value ushr 16) and 0xFF,
        (value ushr 8) and 0xFF,
        value and 0xFF
    ).joinToString(".")
}

/**
 * User-initiated, read-only LAN survey. It probes a short list of TCP ports
 * on a bounded private IPv4 subnet. It does not log in, fingerprint services,
 * read MAC addresses, or send application payloads.
 */
object LanDiscovery {
    private val commonPorts = listOf(80, 443, 22, 445, 554, 8080, 9100)
    private const val CONNECT_TIMEOUT_MS = 220
    private const val MAX_SCAN_SECONDS = 18L
    private const val WORKER_COUNT = 32

    fun run(context: Context): String {
        return try {
            val manager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val active = manager.activeNetwork
                ?: return "لا يوجد اتصال شبكة نشط حالياً."
            val capabilities = manager.getNetworkCapabilities(active)
                ?: return "تعذر قراءة خصائص الشبكة النشطة."
            val supportedTransport =
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
                    capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)
            if (!supportedTransport) {
                return "اكتشاف LAN متاح فقط عبر Wi-Fi أو Ethernet، وليس عبر بيانات الهاتف."
            }

            val properties = manager.getLinkProperties(active)
                ?: return "تعذر قراءة إعدادات واجهة الشبكة."
            val link = properties.linkAddresses.firstOrNull {
                it.address is Inet4Address && it.prefixLength in 24..30
            } ?: return "لم يتم العثور على IPv4 خاص بنطاق /24 إلى /30. لم يبدأ أي مسح."

            val localIp = (link.address as Inet4Address).hostAddress
            val cidr = LanDiscoveryCore.networkCidr(localIp, link.prefixLength)
            val targets = LanDiscoveryCore.targetHosts(localIp, link.prefixLength)
            val gatewayIp = properties.routes.firstOrNull { it.isDefaultRoute }
                ?.gateway?.takeIf { it is Inet4Address }?.hostAddress

            val pool = Executors.newFixedThreadPool(WORKER_COUNT)
            val futures = try {
                pool.invokeAll(
                    targets.map { host ->
                        Callable { probeHost(host, host == gatewayIp) }
                    },
                    MAX_SCAN_SECONDS,
                    TimeUnit.SECONDS
                )
            } finally {
                pool.shutdownNow()
            }

            val found = futures.mapNotNull { future ->
                if (future.isCancelled) null else runCatching { future.get() }.getOrNull()
            }.toMutableList()

            if (gatewayIp != null && found.none { it.address == gatewayIp }) {
                found += LanDeviceResult(gatewayIp, emptyList(), true)
            }
            val ordered = found.distinctBy { it.address }.sortedBy { ipv4SortKey(it.address) }
            val responding = ordered.count { it.openPorts.isNotEmpty() }
            val completed = futures.count { !it.isCancelled }

            buildString {
                appendLine("=== اكتشاف أجهزة الشبكة المحلية ===")
                appendLine("النطاق: " + cidr)
                appendLine("عنوان الهاتف: " + localIp)
                appendLine("البوابة الافتراضية: " + (gatewayIp ?: "غير معروفة"))
                appendLine("نطاق الفحص: " + targets.size + " عنواناً محتملاً")
                appendLine("الاستجابة: " + responding + " جهازاً/خدمة، واكتملت مهام " +
                    completed + " من " + targets.size)
                appendLine()
                if (ordered.isEmpty()) {
                    appendLine("لم تستجب أجهزة لأي منفذ TCP من القائمة المفحوصة.")
                } else {
                    ordered.forEachIndexed { index, device ->
                        appendLine((index + 1).toString() + ". " + device.address)
                        appendLine("   النوع المحتمل: " +
                            LanDiscoveryCore.probableRole(device.openPorts.toSet(), device.isGateway))
                        appendLine(
                            "   المنافذ المستجيبة: " +
                                if (device.openPorts.isEmpty()) "لم يستجب أي منفذ مفحوص"
                                else device.openPorts.joinToString()
                        )
                    }
                }
                appendLine()
                appendLine("المنافذ التي جرى اختبارها: " + commonPorts.joinToString())
                appendLine("المنهج: محاولة TCP CONNECT قصيرة دون إرسال بيانات تطبيق أو محاولة دخول.")
                appendLine("تنبيه: غياب الاستجابة لا يعني أن الجهاز غير موجود؛ قد يحجب جدار الحماية المنافذ أو يرفضها.")
                appendLine("الخصوصية: لا تُقرأ عناوين MAC ولا تُرسل عناوين LAN إلى الإنترنت ولا تُحفظ النتائج.")
                appendLine("حدود النطاق: لا يفحص هذا الإصدار شبكات أوسع من /24 أو شبكات IPv6.")
            }
        } catch (e: SecurityException) {
            "منع Android الوصول إلى الشبكة المحلية. تحقق من أذونات التطبيق وإعدادات الخصوصية."
        } catch (e: Exception) {
            "تعذر إكمال اكتشاف LAN: " + e.javaClass.simpleName + ": " +
                (e.message ?: "خطأ غير محدد")
        }
    }

    private fun probeHost(host: String, isGateway: Boolean): LanDeviceResult? {
        val open = mutableListOf<Int>()
        for (port in commonPorts) {
            if (Thread.currentThread().isInterrupted) break
            val responds = try {
                Socket().use { socket ->
                    socket.connect(InetSocketAddress(host, port), CONNECT_TIMEOUT_MS)
                }
                true
            } catch (_: Exception) {
                false
            }
            if (responds) open += port
        }
        return if (open.isNotEmpty()) LanDeviceResult(host, open, isGateway) else null
    }

    private fun ipv4SortKey(address: String): Long =
        address.split(".").fold(0L) { acc, part -> (acc shl 8) or part.toLong() }
}
