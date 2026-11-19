# NOVA Router Doctor (Android)

Android diagnostic app for home Wi-Fi and internet troubleshooting. Generic network checks are useful with Nokia, Huawei, ZTE, TP-Link, D-Link and other routers. Model-specific GPON/ONT details require the exact model and firmware.

## Current capabilities
- Detects Wi-Fi versus cellular transport and Android's validated-internet state.
- Reads Wi-Fi RSSI, link speed and frequency when Android exposes them.
- Finds the active network's default gateway.
- Tests local router management ports 80 and 443 (best effort).
- Tests external TCP connectivity to Cloudflare and Google.
- Resolves DNS names and tests HTTPS against Google and Cloudflare, recording response time.
- Gives evidence-based first-line troubleshooting guidance.
- Opens the router's local admin page in the browser.
- Copies the diagnostic report.
- Shows optional advanced Termux commands that run the companion shell diagnostic.

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

## Safety and limitations
- No root required.
- Read-only: it does not log in to the router or modify Wi-Fi, WAN, GPON, DNS, VLAN, or firmware settings.
- It never asks for or stores router/Wi-Fi passwords.
- Android and some router firmwares may restrict signal details or block diagnostic ports.
- Failed TCP/ICMP probes are not conclusive proof of a router fault.
- The app provides safe guided actions, not blind automatic configuration changes. Router admin settings must only be changed after confirming the exact model, firmware, ISP configuration and diagnosis.
- Generic network tests work across brands; GPON optical levels, WAN authentication and model-specific repairs need manufacturer/ISP-specific information.

## Build APK
GitHub Actions workflow: **Build NOVA Router Doctor APK**.
Open Repository → Actions → choose the workflow → Run workflow, or wait for the build triggered by a source update. Download the `nova-router-doctor-debug-apk` artifact from a successful run. The APK is a debug build for testing, not a production-signed release.

## Source
Open this directory in Android Studio as a Gradle project. Build with Gradle 8.7, JDK 17 and Android SDK platform 35.
