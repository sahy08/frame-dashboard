#!/usr/bin/env bash
OUT="/opt/dashboard/weather.json"
TMP="$(mktemp)"

if curl -sf --max-time 10 "https://wttr.in/?format=j1" -o "$TMP"; then
  python3 - "$TMP" "$OUT" <<'EOF'
import sys, json

raw = json.load(open(sys.argv[1]))
c   = raw["current_condition"][0]
a   = raw["nearest_area"][0]

out = {
  "temp_c":   c["temp_C"],
  "feels_c":  c["FeelsLikeC"],
  "desc":     c["weatherDesc"][0]["value"],
  "city":     a["areaName"][0]["value"],
  "country":  a["country"][0]["value"],
}
json.dump(out, open(sys.argv[2], "w"))
print(f"weather OK: {out['temp_c']}°C {out['city']}")
EOF
fi

rm -f "$TMP"
