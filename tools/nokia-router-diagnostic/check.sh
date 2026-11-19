#!/data/data/com.termux/files/usr/bin/bash
# Nokia G-2426G-A read-only network diagnostic for Android / Termux.
# This script does NOT log in to the router or change any settings.

set -u

OUT_DIR="$HOME/router-check"
mkdir -p "$OUT_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$OUT_DIR/report-$STAMP.txt"
GW="$(ip route 2>/dev/null | awk '/default/ {print $3; exit}')"

{
  echo "=== NOKIA ROUTER DIAGNOSTIC (READ ONLY) ==="
  echo "Date: $(date)"
  echo "Gateway: ${GW:-not-detected}"
  echo
  echo "=== NETWORK INTERFACES ==="
  ip addr 2>&1
  echo
  echo "=== ROUTES ==="
  ip route 2>&1
  echo
  echo "=== ROUTER PING ==="
  if [ -n "${GW:-}" ]; then
    ping -c 30 -W 2 "$GW" 2>&1
  else
    echo "No default gateway detected; make sure the phone is connected to Wi-Fi."
  fi
  echo
  echo "=== PUBLIC IP PING (1.1.1.1) ==="
  ping -c 30 -W 2 1.1.1.1 2>&1
  echo
  echo "=== DNS TEST ==="
  nslookup google.com 2>&1
  echo
  echo "=== HTTPS TEST ==="
  curl -I --max-time 10 https://google.com 2>&1
  echo
  echo "=== COMPLETE ==="
  echo "Report saved to: $LOG"
} 2>&1 | tee "$LOG"

echo
echo "Diagnostic finished. Report: $LOG"
