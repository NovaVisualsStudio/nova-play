# NOVA Router Doctor (Android)

A lightweight Android diagnostic app for Wi-Fi and internet connectivity. Designed for the Nokia G-2426G-A but useful with other home routers.

## Current capabilities
- Detects whether Android is connected over Wi-Fi or cellular.
- Reads Wi-Fi RSSI, link speed, and frequency when Android permissions and device firmware expose them.
- Identifies the default gateway and performs best-effort local reachability checks.
- Resolves two DNS hostnames.
- Tests HTTPS connectivity and response timing against Google and Cloudflare.
- Displays and copies a diagnostic report.

## Safety and limitations
- Read-only: it does not log in to the router or modify Wi-Fi, WAN, GPON, DNS, or firmware settings.
- It never asks for or stores router/Wi-Fi passwords.
- Android may restrict Wi-Fi signal details unless Location permission is granted and Location services are enabled.
- `InetAddress.isReachable` and gateway port checks are best-effort; routers may block probes or use a different admin port.
- This first APK is a diagnostic baseline, not an automatic repair tool. Router settings must only be changed after identifying the fault and confirming the exact model/firmware behavior.

## Build APK
A GitHub Actions workflow builds a debug APK on every relevant push and can also be started manually:
- Repository → Actions → **Build NOVA Router Doctor APK** → Run workflow.
- Download the `nova-router-doctor-debug-apk` artifact from the completed run.
- Install the APK on Android. Debug APK is for testing, not a signed production release.

## Source
Open this directory in Android Studio as a Gradle project, or build with Gradle 8.7 and JDK 17 using Android SDK platform 35.
