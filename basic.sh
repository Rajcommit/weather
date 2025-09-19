#!/usr/bin/env bash
# Initialize project data files used by the weather ETL workflow.
set -euo pipefail

LOG_FILE=${1:-rx_poc.log}
ACCURACY_FILE=${2:-historical_fc_accuracy.tsv}
INPUT_TEMPLATE=${3:-rx_poc_manual_input.tsv}

ensure_header() {
  local file=$1  ##Local file is in use which limits the scope to this function only
  local header=$2  ##Local file is in use which limits the scope to this function only
  if [[ ! -f $file || ! -s $file ]]; then   ## The file is not thee or the file is there but it is empty**
    printf '%s\n' "$header" >"$file"      ###%s means: "print the argument as a string", "\n menas: "adda new line after prinitn."  prepares output using the format string
    echo "Initialized $file with header"
    return    ## immediately exits the function ensure_header after printing the message.
  fi
  local existing  ##Declares a local variable named existing inside the function
  existing=$(head -n1 "$file" || true)   ##In "exisiting" variable we are storing content of the file, even if the contents fail, use conditon true
  if [[ $existing != "$header" ]]; then   ##Test if the string value in the variable existing is not equal (!=) to the string value in the variable header.
    {
      printf '%s\n' "$header"  #Print the all the string in the header and line by line
      tail -n +2 "$file" 2>/dev/null || true ##consider the lines except the first two lines and if there is any error pass it to null if all good make the condition true	  
    } >"${file}.tmp"    ## more result to filename.tmp
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
