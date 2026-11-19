# NOVA Router Doctor (Android)

An Android diagnostic utility for home Wi-Fi/router troubleshooting across brands. The first build provides passive checks: active Wi-Fi transport, gateway discovery, signal/link information where Android exposes it, TCP reachability, DNS, HTTPS, and guided next steps. It also displays the Termux advanced diagnostic commands already maintained in this repository.

## Build
Run the GitHub Actions workflow **Build NOVA Router Doctor APK**. Download the `nova-router-doctor-debug-apk` artifact from the completed run and install the APK on Android (allow installation from that download source when prompted).

## Safety and scope
- No root required.
- No router password collection.
- No automatic router configuration changes.
- The generic checks work across router brands; model-specific GPON/ONT diagnostics and repairs require model-specific documentation and authenticated access.
- TCP reachability is used instead of relying only on ICMP ping, which is often filtered.
- This is a debug APK, not a production-signed release.
