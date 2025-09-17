#!/usr/bin/env bash
# Report min/max absolute forecast errors over the most recent seven days.
set -euo pipefail

ACCURACY_FILE=${1:-historical_fc_accuracy.tsv}

if [[ ! -f $ACCURACY_FILE ]]; then
  echo "Accuracy file $ACCURACY_FILE does not exist." >&2
  exit 1
fi

mapfile -t recent_accuracy < <(tail -n +2 "$ACCURACY_FILE" | awk -F '\t' '{print $6}' | sed '/^\s*$/d' | tail -n 7)

if ((${#recent_accuracy[@]} == 0)); then
  echo "No accuracy readings available in $ACCURACY_FILE." >&2
  exit 1
fi

if ((${#recent_accuracy[@]} < 7)); then
  echo "Warning: fewer than seven accuracy values available; using ${#recent_accuracy[@]} entries." >&2
fi

abs_values=()
for value in "${recent_accuracy[@]}"; do
  abs_values+=("$(awk -v v="$value" 'BEGIN {if (v < 0) v = -v; printf "%.2f", v}')")
done

read -r min_error max_error <<RANGE
$(printf '%s\n' "${abs_values[@]}" | awk 'NR==1 {min=$1; max=$1} {if ($1+0 < min+0) min=$1; if ($1+0 > max+0) max=$1} END {printf "%.2f %.2f", min, max}')
RANGE

echo "Processed ${#abs_values[@]} accuracy values from $ACCURACY_FILE"
echo "Minimum absolute error: ${min_error}°C"
echo "Maximum absolute error: ${max_error}°C"
