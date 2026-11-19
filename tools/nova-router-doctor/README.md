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
