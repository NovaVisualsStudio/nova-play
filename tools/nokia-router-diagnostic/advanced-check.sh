#!/data/data/com.termux/files/usr/bin/bash
# Nokia G-2426G-A advanced diagnostic for Android / Termux.
# Passive/read-only: no router login, no configuration changes, no credentials.
set -u
export LC_ALL=C

OUT_DIR="$HOME/router-check"
mkdir -p "$OUT_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$OUT_DIR/advanced-report-$STAMP.txt"
GW="$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')"
IFACE="$(ip route 2>/dev/null | awk '/default/ {print $5; exit}')"

have() { command -v "$1" >/dev/null 2>&1; }
section() { printf '\n\n========== %s ==========\n' "$1"; }
run() {
  printf '\n$'
  printf ' %q' "$@"
  printf '\n'
  "$@" 2>&1 || true
}

{
  echo "NOKIA G-2426G-A ADVANCED DIAGNOSTIC (READ ONLY)"
  echo "Date: $(date)"
  echo "Device: Android / Termux"
  echo "Default gateway: ${GW:-NOT DETECTED}"
  echo "Interface: ${IFACE:-NOT DETECTED}"
  echo "Note: ICMP can be filtered; interpret ping with HTTPS/DNS results."
  section "ANDROID NETWORK STATE"
  run ip -brief addr
  run ip route
  if [ -n "${IFACE:-}" ]; then
    run ip -s link show "$IFACE"
  fi

  section "WIFI RADIO SIGNAL (IF EXPOSED BY ANDROID)"
  if [ -r /proc/net/wireless ]; then
    cat /proc/net/wireless
  else
    echo "Android does not expose /proc/net/wireless to this Termux session."
  fi
  if have dumpsys; then
    echo "Wi-Fi service state (SSID/BSSID lines intentionally excluded):"
    dumpsys wifi 2>/dev/null | grep -Ei 'Wi-Fi is|WifiState|mWifiInfo|RSSI|link speed|frequency' | grep -Eiv 'SSID|BSSID|Passpoint' | head -30 || true
  else
    echo "dumpsys unavailable; this is normal on some Android builds."
  fi

  section "LOCAL ROUTER REACHABILITY"
  if [ -n "${GW:-}" ] && have ping; then
    ping -n -c 25 -W 2 "$GW" 2>&1 || true
  else
    echo "Gateway or ping unavailable."
  fi

  section "INTERNET IP REACHABILITY"
  if have ping; then
    echo "--- Cloudflare 1.1.1.1 ---"
    ping -n -c 20 -W 2 1.1.1.1 2>&1 || true
    echo "--- Google DNS 8.8.8.8 ---"
    ping -n -c 20 -W 2 8.8.8.8 2>&1 || true
  else
    echo "ping is not installed."
  fi

  section "DNS RESOLUTION"
  if have nslookup; then
    nslookup google.com 2>&1 || true
    nslookup cloudflare.com 2>&1 || true
  else
    echo "nslookup unavailable; install dnsutils."
  fi

  section "HTTPS CONNECTIVITY AND TIMING"
  if have curl; then
    for url in https://www.google.com https://www.cloudflare.com; do
      echo "--- $url ---"
      curl -L -sS -o /dev/null --max-time 15 \
        -w 'http_code=%{http_code} dns=%{time_namelookup}s connect=%{time_connect}s tls=%{time_appconnect}s total=%{time_total}s bytes_per_sec=%{speed_download}\n' \
        "$url" 2>&1 || true
    done
  else
    echo "curl unavailable."
  fi

  section "OPTIONAL ROUTE TRACE"
  if have traceroute; then
    traceroute -m 8 -w 1 1.1.1.1 2>&1 || true
  elif have tracepath; then
    tracepath -m 8 1.1.1.1 2>&1 || true
  else
    echo "No traceroute/tracepath installed; optional, not required."
  fi

  section "AUTOMATED INTERPRETATION"
  echo "Use the evidence together:"
  echo "- Gateway ping loss/high latency suggests phone-to-router/Wi-Fi trouble, unless ICMP is filtered."
  echo "- Gateway stable but both public IP tests and HTTPS fail suggests WAN/ISP/router uplink trouble."
  echo "- Public IP reachability works but DNS lookups fail suggests DNS trouble."
  echo "- DNS works but HTTPS fails suggests TLS, filtering, captive portal, or broader connectivity issue."
  echo "- All tests pass but browsing is slow: run a separate speed test near the router and compare 2.4 GHz congestion."
  echo
  echo "No settings were changed. No SSID, BSSID, passwords, or router credentials are intentionally collected."
  echo "Report path: $LOG"
} 2>&1 | tee "$LOG"

echo
echo "Finished. Report saved at: $LOG"
