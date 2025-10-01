#!/usr/bin/env bash
set -euo pipefail

min_bash_major=4

if (( BASH_VERSINFO[0] < min_bash_major )); then
  echo "Bash ${min_bash_major}+ is required; found ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}." >&2
  exit 1
fi

required_tools=(curl awk sed grep cut date wget python3)
missing=()

for tool in "${required_tools[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    missing+=("$tool")
  fi
done

if (( ${#missing[@]} > 0 )); then
  printf 'Missing required tool(s): %s\n' "${missing[*]}" >&2
  exit 1
fi

python_version=$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')
python_major=${python_version%%.*}
python_minor=${python_version#*.}

if (( python_major < 3 || (python_major == 3 && python_minor < 8) )); then
  echo "Python 3.8+ is required; found ${python_version}." >&2
  exit 1
fi

shopt -s nullglob
shell_scripts=(*.sh)
shopt -u nullglob

if (( ${#shell_scripts[@]} == 0 )); then
  echo "No shell scripts found to mark executable." >&2
  exit 1
fi

chmod +x "${shell_scripts[@]}"
echo "Environment checks passed and shell scripts marked executable."
