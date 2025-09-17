#!/usr/bin/env bash
# Generate historical forecast accuracy metrics from rx_poc.log entries.
set -euo pipefail

LOG_FILE=${1:-rx_poc.log}
OUTPUT_FILE=${2:-historical_fc_accuracy.tsv}

if [[ ! -f $LOG_FILE ]]; then
  echo "Input log $LOG_FILE does not exist." >&2
  exit 1
fi

TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE"' EXIT

printf 'year\tmonth\tday\tobs_temp\tfc_temp\taccuracy\taccuracy_range\n' >"$TMP_FILE"

AWK_SCRIPT='BEGIN {FS="\t"}
NR==1 {next}
/^#/ {next}
/^[[:space:]]*$/ {next}
{
  if (!has_prev) {
    prev_fc=$5;
    has_prev=1;
    next;
  }
  obs=$4+0
  fc_prev=prev_fc+0
  err=fc_prev-obs
  abs_err=(err < 0) ? -err : err
  if (abs_err <= 1) {
    range="excellent"
  } else if (abs_err <= 2) {
    range="good"
  } else if (abs_err <= 4) {
    range="fair"
  } else {
    range="poor"
  }
  printf "%s\t%s\t%s\t%.1f\t%.1f\t%.1f\t%s\n", $1, $2, $3, obs, fc_prev, err, range
  prev_fc=$5;
  records++
}'

if ! awk "$AWK_SCRIPT" "$LOG_FILE" >>"$TMP_FILE"; then
  echo "Failed to compute forecast accuracy" >&2
  exit 1
fi

line_count=$(wc -l <"$TMP_FILE")
if (( line_count <= 1 )); then
  echo "Log $LOG_FILE does not yet have enough entries to calculate accuracy." >&2
  mv "$TMP_FILE" "$OUTPUT_FILE"
  exit 0
fi

mv "$TMP_FILE" "$OUTPUT_FILE"
echo "Wrote forecast accuracy metrics to $OUTPUT_FILE"
