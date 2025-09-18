# Historical Weather Forecast Tracker

## Overview
Collect daily weather observations for Casablanca (or another city) and compare them with the forecast from the previous day. The scripts in this project build a running log, calculate forecast accuracy, and summarize weekly performance.

## What You Need
- Bash 4+, `curl`, `grep`, `cut`, `sed`, `awk`, `date`, `wget` (all standard on most Linux/macOS systems)
- Python 3.8+ for the JSON parsing snippet embedded in `rx_poc.sh`
- Network access to [wttr.in](https://wttr.in) if you want live data
- Permissions to make scripts executable and, optionally, to add a cron job

## Setup
1. Make sure the scripts are executable: `chmod +x *.sh`.
2. Run `./basic.sh` once. It creates the log (`rx_poc.log`), accuracy file (`historical_fc_accuracy.tsv`), and a template for manual entries (`rx_poc_manual_input.tsv`).
3. Open the scripts in your editor if you want to change the default city or tweak output paths.

## Daily Workflow
1. **Collect weather data** – `./rx_poc.sh [CITY]`
   - Pulls the latest observation and next-day forecast from wttr.in.
   - Appends a tab-delimited entry to `rx_poc.log` (duplicates for the same day are skipped).
   - Saves the raw API response to `weather_report.json` for debugging.
2. **Build accuracy history** – `./fc_accuracy.sh [input_log] [output_file]`
   - Defaults to `./fc_accuracy.sh rx_poc.log historical_fc_accuracy.tsv`.
   - Calculates the signed error (`forecast - observed`) and classifies the accuracy range.
3. **Review weekly stats** – `./weekly_stats.sh [accuracy_file]`
   - Defaults to `./weekly_stats.sh historical_fc_accuracy.tsv`.
   - Reports the minimum and maximum absolute error from the most recent seven records.

### Manual Data Entry (Optional)
1. Add rows to `rx_poc_manual_input.tsv` using the same header as `rx_poc.log`.
2. Run `./fc_accuracy.sh rx_poc_manual_input.tsv manual_accuracy.tsv` to generate accuracy metrics without calling the API.
3. Use `manual_accuracy.tsv` as the input to `./weekly_stats.sh` if you want to continue the analysis offline.

## Detailed Script Guides
- `basic.txt` – Line-by-line explanation of `basic.sh` initialization logic.
- `rx_poc.txt` – Detailed walkthrough of the data collection script and its safeguards.
- `fc_accuracy.txt` – Commentary on how forecast accuracy metrics are derived.
- `weekly_stats.txt` – Notes covering recent-period summary calculations.
- `weather-pipeline.txt` – Full explanation of the GitHub Actions workflow.

## Runtime Requirements & Environment
- **Local execution:** Scripts rely on the tools listed under *What You Need*; no additional services are required.
- **Environment variables:** None are mandatory for local runs. The GitHub Actions workflow injects the dispatch `city` input as a `CITY` environment variable for the pipeline step. When running locally, pass `-c <city>` to `rx_poc.sh` to override the default.
- **File paths:** Override default output locations by passing positional arguments to `basic.sh` and `fc_accuracy.sh`, or the `-l`/`-o` flags to `rx_poc.sh`.

## Automating the Scripts
- **Cron (local machine):** Schedule `rx_poc.sh` at Casablanca noon. Example for a system in UTC-5:
  ```cron
  0 6 * * * /path/to/repo/rx_poc.sh >> /path/to/repo/rx_poc_cron.log 2>&1
  ```
- **GitHub Actions:** Trigger the *Weather Data Pipeline* workflow in the Actions tab. Provide the optional `city` input to run against another location.

## File Reference
| File | Purpose |
| --- | --- |
| `basic.sh` | Creates starter files with the correct headers. |
| `rx_poc.sh` | Primary ETL script that fetches weather data and updates `rx_poc.log`. |
| `rx_poc.log` | Tab-delimited history of observed and forecast temperatures. |
| `fc_accuracy.sh` | Converts the log into accuracy metrics (`historical_fc_accuracy.tsv`). |
| `historical_fc_accuracy.tsv` | Forecast accuracy data with signed error and qualitative range. |
| `rx_poc_manual_input.tsv` | Template for manual entries when the API is unavailable. |
| `weekly_stats.sh` | Reports weekly minimum and maximum absolute errors. |
| `weather_report.json` | Raw API response stored by `rx_poc.sh` (generated on demand). |

## Troubleshooting & Tips
- If a script complains about permissions, re-run `chmod +x *.sh`.
- Empty outputs usually mean the input file is missing or has fewer than two rows; open the file to confirm.
- When wttr.in is unreachable, switch to the manual template until the network returns.
- Use `bash -x ./script.sh` to print every command as it runs when debugging.

## Credits
Adapted from course material by Jeff Grossman.
