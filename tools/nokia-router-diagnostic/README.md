# Nokia G-2426G-A Router Diagnostic

Read-only network checks for Android phones running Termux.

## What it checks
- Android network interfaces and default route
- Ping to the local router gateway
- Ping to Cloudflare DNS (1.1.1.1)
- DNS lookup for google.com
- HTTPS connectivity to google.com

## What it does NOT do
- It does not log in to the router.
- It does not collect router passwords or Wi-Fi passwords.
- It does not change Wi-Fi, WAN, GPON, DNS, or firmware settings.
- It cannot conclusively identify an ISP fault from ping alone; ICMP may be filtered.

## Install and run

In Termux:

```bash
pkg update -y
pkg install -y iproute2 iputils dnsutils curl
curl -L https://raw.githubusercontent.com/NovaVisualsStudio/nova-play/main/tools/nokia-router-diagnostic/check.sh -o check.sh
chmod +x check.sh
./check.sh
```

The report is saved under `~/router-check/`. Review it before sharing; it may include local network addresses. Never share router credentials.

Designed for Nokia G-2426G-A troubleshooting, but the basic network tests work with other routers too.


## Advanced Wi-Fi / WAN diagnosis

Use the expanded passive diagnostic when the basic report is not enough. It checks interface counters, Wi-Fi signal information when Android exposes it, the router gateway, two public IP endpoints, two DNS names, HTTPS timing, and an optional route trace. It deliberately filters SSID/BSSID output and never changes router or phone network settings.

Install the additional optional route-trace package and run:

```bash
pkg update -y
pkg install -y iproute2 iputils dnsutils curl traceroute
mkdir -p ~/router-check
cd ~/router-check
curl -L https://raw.githubusercontent.com/NovaVisualsStudio/nova-play/main/tools/nokia-router-diagnostic/advanced-check.sh -o advanced-check.sh
chmod +x advanced-check.sh
bash advanced-check.sh
```

The report is saved as `~/router-check/advanced-report-<timestamp>.txt`. To display the newest report:

```bash
ls -t ~/router-check/advanced-report-*.txt | head -1
```

Then run `cat` with the exact path printed by that command. Review it before sharing. The script is diagnostic only: it cannot access Nokia's admin-only GPON/WAN configuration and does not automatically apply repairs. Do not share Wi-Fi/router passwords, public IP addresses, or other private account details.
