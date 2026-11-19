# NOVA Router Doctor (Android)

Android Wi-Fi and internet diagnostics with an offline router-model registry and repair knowledge base.

## New database and repair features
- Search the curated local model registry and a bundled OpenWrt Table of Hardware snapshot (the importer fetches the upstream daily TSV export when the APK is built).
- Includes a source-checked Nokia G-2426G-A GPON ONT record with official product references and model-specific safety warnings.
- Provides links to the OpenWrt Table of Hardware and manufacturer support portals.
- Includes Arabic safe-troubleshooting playbooks for weak Wi-Fi, interference, no WAN internet, DNS failure, slow throughput, one-device-only faults, and overheating/power issues.
- The OpenWrt catalogue is linked as an upstream live source; its entire database is not copied into this app.

## General diagnostic capabilities
- Detects Wi-Fi versus cellular transport and Android's validated-internet state.
- Reads Wi-Fi RSSI, link speed and frequency where Android exposes them.
- Finds the active network's default gateway.
- Tests local router management ports 80 and 443 (best effort).
- Tests external TCP connectivity to Cloudflare and Google.
- Resolves DNS names and tests HTTPS against Google and Cloudflare, recording response time.
- Gives evidence-based first-line troubleshooting guidance.
- Opens the router's local admin page and copies the diagnostic report.
- Shows optional advanced Termux commands.

## Network lab (Wi-Fi inspection and internet speed)
- A separate in-app network lab reads Android's active-network state, validated-internet capability, local IP, default gateway, DNS servers, interface name, Wi-Fi RSSI, negotiated link rate and radio frequency where Android exposes them.
- The lab provides an on-demand Cloudflare-based HTTP download/upload throughput test (8 MB download + 2 MB upload) and nine HTTPS response samples. It reports mean, median, P95, standard deviation, mean absolute change between adjacent samples, and failed-sample ratio. These are HTTP(S) transaction timings, not ICMP ping, UDP jitter, or packet-loss measurements.
- The speed test is user-initiated, runs over HTTPS and does not need router credentials. It can consume around 10 MB per run. Results depend on the external test endpoint, route, congestion, Wi-Fi signal, device and server load; repeat tests and compare near the router versus farther away.
- Wi-Fi link speed is a negotiated radio link rate, not measured internet throughput. RSSI is a signal-strength indicator, not a distance or speed measurement.
- A deterministic `NetworkMetrics` core computes percentiles, spread, adjacent-sample variation, failed-sample ratio, loaded-latency increase classification, and decimal Mbps. JVM unit tests cover the metric math and invalid inputs; CI runs these tests before packaging the APK.\n- Adds an opt-in loaded-latency / Bufferbloat approximation: HTTPS P95 latency is sampled before and during concurrent 12 MB download + 3 MB upload load. It reports added P95 latency and a clearly labelled heuristic grade. It is not an RFC/RRUL-grade test, ICMP ping, UDP jitter, or packet-loss measurement; those require a dedicated measurement server and protocol support.
- On-demand nearby Wi-Fi scan is now implemented with Android's `WifiManager` scan API, runtime location permission, Location Services check, API 33 receiver registration, and safe receiver cleanup. It lists visible SSIDs, band, frequency, channel, RSSI, security family and scan-result age; BSSIDs are deliberately hidden.
- A pure Kotlin Wi-Fi channel analyzer maps common 2.4/5/6 GHz frequencies and ranks 2.4 GHz channels 1/6/11 using nearby AP signal-weighted overlap. This is a neighbor-AP pressure heuristic, not RF spectrum or airtime utilization. Android scan throttling, cached results, permission and OEM restrictions remain.
- Wi-Fi channel mapping and ranking have JVM unit tests; CI runs all unit tests before APK packaging.
- Adds an opt-in LAN discovery screen for Wi-Fi/Ethernet IPv4 private subnets from /24 to /30 only. It checks a bounded list of common TCP ports with short connection timeouts, performs no login or service-banner probing, and never reads MAC addresses or sends LAN inventory to a server. Device roles are explicitly labelled as probable hints, not verified identities.
- LAN discovery is covered by JVM tests for subnet boundaries, private-range restrictions and role hints. Networks larger than /24 and IPv6 are intentionally not scanned in this version.
- Android local-network permission migration: this app currently targets SDK 32. Android 17 requires apps targeting SDK 37+ to declare and request `ACCESS_LOCAL_NETWORK` before raw LAN socket access; revisit this before raising targetSdk. See https://developer.android.com/privacy-and-security/local-network-permission.

### Open-source engineering references reviewed
- WaveMap: https://github.com/CapptainnCWC/wavemap — Wi-Fi survey, signal history, channel spectrum and heatmaps. Reference only; verify license and code compatibility before copying.
- NetInspector: https://github.com/EnthusiastDeveloper/NetInspector — Android Wi-Fi/LAN diagnostics and ping/traceroute/DNS tooling. Its README states Android 13+ minimum, so it is not a drop-in dependency for this app's current minSdk 23.
- WiFiAnalyzer: https://github.com/VREMSoftwareDevelopment/WiFiAnalyzer — mature Android Wi-Fi signal/channel analysis project, GPL-3.0. Treat as a reference unless the app's licensing strategy is deliberately made GPL-compatible.
- LibreSpeed Android: https://github.com/librespeed/speedtest-android — open-source Android speed-test client/template with download, upload, ping and jitter. LGPL-3.0; its template is configured for LibreSpeed servers, so this app currently uses a small native HTTP measurement implementation.
- Android Wi-Fi scanning guidance: https://developer.android.com/develop/connectivity/wifi/wifi-scan — official permission, throttling and freshness limitations for scan results.

## Device database sources and reuse
1. OpenWrt Table of Hardware: https://toh.openwrt.org/ and upstream data endpoint https://openwrt.org/toh.json. The hardware data is community-maintained; OpenWrt documents the JSON dump and nightly generation process. Wiki data is generally under CC BY-SA 4.0; preserve attribution and share-alike requirements for any extracted/redistributed records. The ToH web application's code repository is GPL-2.0; do not assume that code license automatically applies to the underlying wiki data.
2. OpenWrt ToH repository: https://github.com/openwrt/toh-openwrt-org
3. OpenDeviceDB: https://github.com/opendevicedb/opendevicedb — use as a discovery index for open-firmware/open-protocol device projects, not as a universal consumer router database. Check LICENSE-DATA.md and each upstream dataset license before importing.
4. The build importer `sync_openwrt_db.py` uses the upstream tab-separated ZIP export at https://openwrt.org/_media/toh_dump_tab_separated.zip, normalizes fields and preserves a per-record source URL. The exported data is refreshed at APK build time; source records may be incomplete or community-edited.
5. Nokia G-2426G-A product information: https://onestore.nokia.com/asset/f/207658/ and product guide https://assets-us-01.kc-usercontent.com/b33dc2a4-d1b6-0080-5fc3-5fd76f8f7dab/8cab7445-2d3a-4aa4-a03b-d8e812114300/G-2426G-A.pdf. Only a short factual specification summary and source links are stored here; Nokia's proprietary guide is not republished.

Manufacturer support portals included in the registry: Nokia, TP-Link, Huawei, ZTE, D-Link, ASUS, NETGEAR, MikroTik and Ubiquiti. Always select the exact hardware revision and country/ISP variant before using firmware or configuration instructions.

## Safety and limitations
- No root required.
- Read-only network diagnostics; no router login or automatic changes to Wi-Fi, WAN, GPON, DNS, VLAN or firmware.
- No collection of Wi-Fi/router passwords.
- Android may restrict signal details; routers may block diagnostic ports.
- Failed TCP/ICMP probes are not conclusive proof of router failure.
- OpenWrt compatibility does not imply a router can safely be flashed with OpenWrt. ISP-supplied GPON ONTs may be locked or provisioned remotely.
- Do not change GPON serial/LOID, OMCI, VLAN, PPPoE, WAN credentials, regional radio settings, or firmware based only on generic advice.
- A model record must include manufacturer, exact model, hardware revision where applicable, source URL, checked date, and confidence. Never infer exact firmware from model name alone.

## Termux companion
The advanced read-only script is at:
`tools/nokia-router-diagnostic/advanced-check.sh`

Install Termux from F-Droid, then run:

```bash
pkg update -y
pkg install -y iproute2 iputils dnsutils curl traceroute
mkdir -p ~/router-check && cd ~/router-check
curl -L https://raw.githubusercontent.com/NovaVisualsStudio/nova-play/main/tools/nokia-router-diagnostic/advanced-check.sh -o advanced-check.sh
chmod +x advanced-check.sh
bash advanced-check.sh
```

## Build APK
GitHub Actions workflow: **Build NOVA Router Doctor APK**.
Open Repository → Actions → choose the workflow → Run workflow, or wait for a build triggered by source updates. Download the `nova-router-doctor-debug-apk` artifact from a successful run. This is a debug APK for testing, not a production-signed release.

## Android build requirements
Gradle 8.7, JDK 17 and Android SDK platform 35.
