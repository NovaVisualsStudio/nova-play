#!/usr/bin/env python3
"""Fetch OpenWrt's public ToH TSV export and build a compact attributed JSON index."""
import csv
import io
import json
import sys
import urllib.request
import zipfile
from datetime import datetime, timezone
from pathlib import Path

SOURCE_URL = "https://openwrt.org/_media/toh_dump_tab_separated.zip"
OUT = Path(__file__).resolve().parent / "app/src/main/assets/openwrt_devices.json"
FIELDS = [
    "brand", "model", "version", "page", "hwdata", "oem", "deviceid",
    "target", "subtarget", "supported_current_release", "supported_since_release",
    "cpu", "cores", "mhz", "flash", "ram", "switch", "wlan_hardware",
    "2.4ghz", "5.0ghz", "6.0ghz", "eth_100", "eth_1g", "eth_2.5g",
    "eth_5g", "eth_10g", "vlan", "device_type", "availability",
    "firmware", "install", "upgrade", "recovery", "wlan_driver",
    "oem_device_url", "fcc"
]

def main():
    req = urllib.request.Request(SOURCE_URL, headers={"User-Agent": "NOVA-Router-Doctor/1.0"})
    with urllib.request.urlopen(req, timeout=45) as response:
        archive = zipfile.ZipFile(io.BytesIO(response.read()))
    names = archive.namelist()
    if not names:
        raise RuntimeError("OpenWrt export archive is empty")
    with archive.open(names[0]) as raw:
        text = io.TextIOWrapper(raw, encoding="utf-8", errors="replace")
        reader = csv.DictReader(text, delimiter="\t")
        rows = []
        for row in reader:
            clean = {k: (v or "").strip() for k, v in row.items() if k}
            brand = clean.get("brand", "")
            model = clean.get("model", "")
            if not brand and not model:
                continue
            item = {key: clean.get(key, "") for key in FIELDS if clean.get(key, "")}
            item["source_url"] = "https://openwrt.org/toh/" + clean.get("page", "").replace(":", "/")
            item["source_type"] = "OpenWrt community hardware record"
            rows.append(item)
    payload = {
        "schema_version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source": SOURCE_URL,
        "source_project": "OpenWrt Table of Hardware",
        "attribution": "OpenWrt Wiki contributors — https://openwrt.org/toh/",
        "data_license": "CC BY-SA 4.0 (OpenWrt Wiki hardware data; verify upstream terms before redistribution)",
        "notice": "OpenWrt support listing is not proof that a device can safely run OpenWrt. ISP-customized GPON/ONT models may be locked or unsupported. Match exact hardware revision.",
        "count": len(rows),
        "devices": rows,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {len(rows)} OpenWrt device records to {OUT}")
    if len(rows) < 100:
        raise RuntimeError(f"Unexpectedly small device index ({len(rows)} records); refusing to package incomplete data")

if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
