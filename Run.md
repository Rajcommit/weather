# Run Guide

Follow these steps to initialize the weather forecast tracker, collect data, and generate accuracy metrics.

## 1. Prepare the Environment
- Ensure Bash 4+, `curl`, `awk`, `sed`, `grep`, `cut`, `date`, `wget`, and Python 3.8+ are installed.
- Make the shell scripts executable once per clone:
  ```bash
./prepare_environmet.sh
  chmod +x *.sh
  ```

## 2. Initialize Required Files
Run the bootstrap script to create the working files with the correct headers:
```bash
./basic.sh
```
This populates:
- `rx_poc.log` — observation + forecast log.
- `historical_fc_accuracy.tsv` — accuracy table scaffold.
- `rx_poc_manual_input.tsv` — manual-entry template with comment guidance.

## 3. Collect Daily Weather Data
Fetch the current observation and tomorrow's forecast (defaults to Casablanca):
```bash
./rx_poc.sh
```
Key behaviors:
- Saves the full API payload to `weather_report.json`.
- Appends one tab-delimited record per day to `rx_poc.log` (duplicate dates are skipped).
- Use another city with `./rx_poc.sh -c "City Name"` or change log paths with `-l` / `-o`.

## 4. Build Forecast Accuracy History
Translate the observation log into accuracy metrics:
```bash
./fc_accuracy.sh rx_poc.log historical_fc_accuracy.tsv
```
The script compares each day's observation to the previous forecast, writes signed errors, and classifies each into `excellent`, `good`, `fair`, or `poor` ranges.

## 5. Review Weekly Error Range
Summarize the most recent seven accuracy values (or fewer if the log is short):
```bash
./weekly_stats.sh historical_fc_accuracy.tsv
```
The output reports the minimum and maximum absolute error over the inspected span.

## 6. Optional: Manual Data Entry Workflow
If wttr.in is unavailable:
1. Add tab-separated rows beneath the header in `rx_poc_manual_input.tsv`.
2. Run `./fc_accuracy.sh rx_poc_manual_input.tsv manual_accuracy.tsv`.
3. Feed `manual_accuracy.tsv` into `./weekly_stats.sh` to keep the analysis offline.

## 7. Optional Automation
- **Cron:** Schedule `rx_poc.sh` around local noon for the target city, appending to a log if desired.
- **GitHub Actions:** Trigger the documented *Weather Data Pipeline* from the repository's Actions tab and supply the optional `city` input.

## Troubleshooting Tips
- Re-run `chmod +x *.sh` if you encounter permission denied errors.
- Use `bash -x ./script.sh` for verbose debugging output.
- Empty reports typically mean the input file is missing headers or entries; open the file to confirm.
