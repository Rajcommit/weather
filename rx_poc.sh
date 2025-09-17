#!/usr/bin/env bash
# Collect Casablanca weather observations and forecasts from wttr.in.
set -euo pipefail

CITY="Casablanca"
LOG_FILE="rx_poc.log"
RAW_OUTPUT="weather_report.json"
TZ_REGION="Africa/Casablanca"

declare -a CLEANUP_FILES

usage() {
  cat <<USAGE
Usage: ${0##*/} [-c city] [-l log_file] [-o raw_output]
  -c city        City name understood by wttr.in (default: Casablanca)
  -l log_file    Log file to append tab-delimited weather records (default: rx_poc.log)
  -o raw_output  Path to store the most recent raw API payload (default: weather_report.json)
USAGE
}

while getopts ":c:l:o:h" opt; do
  case "$opt" in
    c) CITY=$OPTARG ;;
    l) LOG_FILE=$OPTARG ;;
    o) RAW_OUTPUT=$OPTARG ;;
    h)
      usage
      exit 0
      ;;
    :)
      echo "Missing value for -$OPTARG" >&2
      usage >&2
      exit 1
      ;;
    ?)
      echo "Unknown option: -$OPTARG" >&2
      usage >&2
      exit 1
      ;;
  esac
done

mkdir -p "$(dirname "$RAW_OUTPUT")"
API_URL="https://wttr.in/${CITY// /%20}?format=j1"
TEMP_JSON=$(mktemp)
CLEANUP_FILES+=("$TEMP_JSON")
trap 'for f in "${CLEANUP_FILES[@]}"; do [[ -f $f ]] && rm -f "$f"; done' EXIT

if ! curl -fsS --retry 3 --retry-delay 2 "$API_URL" -o "$TEMP_JSON"; then
  echo "Failed to download weather data from wttr.in for $CITY" >&2
  exit 1
fi

if ! cp "$TEMP_JSON" "$RAW_OUTPUT"; then
  echo "Unable to write raw response to $RAW_OUTPUT" >&2
  exit 1
fi

read -r OBS_TEMP FC_TEMP <<VALUES
$(python3 - "$TEMP_JSON" <<'PY'
import json
import sys
from pathlib import Path

payload_path = Path(sys.argv[1])
with payload_path.open("r", encoding="utf-8") as handle:
    data = json.load(handle)

try:
    current = data["current_condition"][0]
    obs = float(current["temp_C"])
except (KeyError, IndexError, ValueError) as exc:  # pragma: no cover
    raise SystemExit(f"Unable to read observed temperature: {exc}") from exc

weather_periods = data.get("weather", [])
if len(weather_periods) >= 2:
    tomorrow = weather_periods[1]
else:
    tomorrow = weather_periods[0] if weather_periods else None

if not tomorrow:
    raise SystemExit("Weather forecast data is unavailable in the payload")

hourly = tomorrow.get("hourly", [])
if not hourly:
    raise SystemExit("Hourly forecast data missing from payload")

midday_slot = min(
    hourly,
    key=lambda entry: abs(int(entry.get("time", "0") or "0") - 1200),
)

try:
    forecast = float(midday_slot["tempC"])
except (KeyError, ValueError) as exc:  # pragma: no cover
    raise SystemExit(f"Unable to read forecast temperature: {exc}") from exc

print(f"{obs:.1f} {forecast:.1f}")
PY
)
VALUES

if [[ -z ${OBS_TEMP:-} || -z ${FC_TEMP:-} ]]; then
  echo "Failed to parse observed or forecast temperature" >&2
  exit 1
fi

expected_header=$'year\tmonth\tday\tobs_temp\tfc_temp'
if [[ ! -f $LOG_FILE || ! -s $LOG_FILE ]]; then
  printf '%s\n' "$expected_header" >"$LOG_FILE"
elif [[ $(head -n1 "$LOG_FILE") != $expected_header ]]; then
  {
    printf '%s\n' "$expected_header"
    tail -n +2 "$LOG_FILE" 2>/dev/null || true
  } >"$LOG_FILE.tmp"
  mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

YEAR=$(TZ="$TZ_REGION" date +%Y)
MONTH=$(TZ="$TZ_REGION" date +%m)
DAY=$(TZ="$TZ_REGION" date +%d)

if awk -F '\t' -v y="$YEAR" -v m="$MONTH" -v d="$DAY" 'NR>1 && $1==y && $2==m && $3==d {exit 0} END {exit 1}' "$LOG_FILE"; then
  echo "An entry for $YEAR-$MONTH-$DAY already exists in $LOG_FILE. Skipping append." >&2
  exit 0
fi

printf '%s\t%s\t%s\t%.1f\t%.1f\n' "$YEAR" "$MONTH" "$DAY" "$OBS_TEMP" "$FC_TEMP" >>"$LOG_FILE"
echo "Appended weather record for $YEAR-$MONTH-$DAY to $LOG_FILE"
