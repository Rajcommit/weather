#!/usr/bin/env bash
# Initialize project data files used by the weather ETL workflow.
set -euo pipefail

LOG_FILE=${1:-rx_poc.log}
ACCURACY_FILE=${2:-historical_fc_accuracy.tsv}
INPUT_TEMPLATE=${3:-rx_poc_manual_input.tsv}

ensure_header() {
  local file=$1
  local header=$2
  if [[ ! -f $file || ! -s $file ]]; then
    printf '%s\n' "$header" >"$file"
    echo "Initialized $file with header"
    return
  fi
  local existing
  existing=$(head -n1 "$file" || true)
  if [[ $existing != "$header" ]]; then
    {
      printf '%s\n' "$header"
      tail -n +2 "$file" 2>/dev/null || true
    } >"${file}.tmp"
    mv "${file}.tmp" "$file"
    echo "Reset header for $file"
  fi
}

ensure_log() {
  ensure_header "$LOG_FILE" $'year\tmonth\tday\tobs_temp\tfc_temp'
}

ensure_accuracy() {
  ensure_header "$ACCURACY_FILE" $'year\tmonth\tday\tobs_temp\tfc_temp\taccuracy\taccuracy_range'
}

ensure_template() {
  ensure_header "$INPUT_TEMPLATE" $'year\tmonth\tday\tobs_temp\tfc_temp'
  if ! grep -q '^#' "$INPUT_TEMPLATE"; then
    {
      printf '%s\n' $'# Add additional rows below using tab-separated values, e.g.:'
      printf '%s\n' $'# 2024\t05\t01\t23.5\t24.0'
    } >>"$INPUT_TEMPLATE"
  fi
}

ensure_log
ensure_accuracy
ensure_template
