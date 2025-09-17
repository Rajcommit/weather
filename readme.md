# Practice Project: Historical Weather Forecast Comparison to Actuals

## Executive Summary
This repository contains the scaffolding for an end-to-end practice project that compares historical weather forecasts with observed temperatures for Casablanca, Morocco. It guides learners through constructing a lightweight ETL workflow in Bash, persisting raw and derived metrics, and scheduling daily updates so that the resulting log can be analyzed for forecast accuracy. The material is organized as six progressive exercises that cover data acquisition, transformation, storage, quality monitoring, and weekly analytics.

## Learning Objectives
By following the exercises in this project you will learn how to:
- Initialize a persistent weather report log (`rx_poc.log`) with tab-delimited fields for year, month, day, observed temperature, and forecast temperature.
- Automate data collection with Bash by calling the wttr.in API for Casablanca and capturing the current observed temperature alongside the following day's forecast.
- Extract, clean, and normalize weather readings so they can be reused in downstream analytics and historical accuracy tracking.
- Schedule the collection script to run daily at local noon in Casablanca via cron.
- Compute day-level forecast error classifications and maintain a historical accuracy dataset.
- Generate weekly statistics on forecast performance, including minimum and maximum absolute errors.

## Repository Structure
| File | Description |
| --- | --- |
| `rx_poc.sh` | Intended Bash ETL script that downloads Casablanca weather data, extracts current and forecast temperatures, and appends a record to `rx_poc.log`. **Note:** the file is currently empty and must be populated with the logic outlined in Exercises 2 and 3 below.【62e87d†L1-L5】 |
| `rx_poc.log` | Tab-delimited log file that stores the daily observations. Presently empty pending script execution.【62e87d†L5-L6】 |
| `fc_accuracy.sh` | Placeholder for the historical forecast accuracy calculator described in Exercise 5. The script has not yet been implemented.【62e87d†L1-L4】 |
| `weekly_stats.sh` | Bash utility that ingests the last seven forecast accuracy values, converts them to absolute errors, and reports weekly min/max statistics. The current version includes extra tutorial artifacts ("Copied!", "Wrap Toggled!") that should be removed before production use.【d86971†L1-L34】 |
| `basic.sh` | Empty helper script placeholder.【62e87d†L1-L2】 |

## Prerequisites
- Linux or macOS environment with Bash 4+, `curl`, `wget`, `grep`, `cut`, `head`, `tail`, and `date` available.
- Network access to `wttr.in` for live weather retrieval and to IBM Skills Network for synthetic datasets.
- Permission to install cron jobs if you plan to schedule automated execution.

## Exercise 1 – Initialize the Weather Log
1. Create the log file and apply a header:
   ```bash
   touch rx_poc.log
   echo -e "year\tmonth\tday\tobs_temp\tfc_temp" > rx_poc.log
   ```
2. Confirm the file uses tabs to delimit columns. This ensures compatibility with downstream parsing utilities.

## Exercise 2 – Download Raw Weather Data
1. Create the primary ETL script and make it executable:
   ```bash
   cat <<'EOT' > rx_poc.sh
   #!/bin/bash
   city="Casablanca"
   curl -s "https://wttr.in/${city}?T" --output weather_report
   EOT
   chmod u+x rx_poc.sh
   ```
2. Verify the script runs and captures a `weather_report` file. Inspect the raw response to understand the layout of temperature readings.

## Exercise 3 – Extract and Load Required Data
1. Extend `rx_poc.sh` to parse the current observed temperature (`obs_temp`) and the forecasted noon temperature for the next day (`fc_temp`). Use pipelines with `grep`, `cut`, and `sed` to strip ANSI color codes before storing numeric values.
2. Capture Casablanca's local date by setting the `TZ='Morocco/Casablanca'` environment variable and calling `date` for year, month, and day.
3. Append a tab-delimited record to `rx_poc.log`:
   ```bash
   printf "%s\t%s\t%s\t%s\t%s\n" "$year" "$month" "$day" "$obs_temp" "$fc_temp" >> rx_poc.log
   ```
4. Repeat execution daily to build a historical log. Consider adding defensive checks for API failures and malformed data.

## Exercise 4 – Schedule Daily Collection
1. Determine the offset between your server's timezone and Casablanca (UTC+1). Use `date` and `date -u` to compare system time with UTC.
2. Add a cron job that executes `rx_poc.sh` at the calculated system time corresponding to Casablanca noon. Example for a system on UTC-5:
   ```cron
   0 6 * * * /home/project/rx_poc.sh >> /home/project/rx_poc_cron.log 2>&1
   ```
3. Maintain a cron-specific log to troubleshoot failures and confirm daily runs.

## Exercise 5 – Report Historical Forecast Accuracy
1. Initialize the derived dataset:
   ```bash
   echo -e "year\tmonth\tday\tobs_temp\tfc_temp\taccuracy\taccuracy_range" > historical_fc_accuracy.tsv
   ```
2. Implement `fc_accuracy.sh` to:
   - Retrieve the prior day's forecast and today's observation from `rx_poc.log`.
   - Compute the signed error (`forecast - observed`).
   - Classify accuracy as `excellent`, `good`, `fair`, or `poor` based on ±1–4 °C thresholds.
   - Append the enriched record to `historical_fc_accuracy.tsv`.
3. Extend the script with loops to process the full log so that every day has an accuracy assessment.

## Exercise 6 – Weekly Statistics on Forecast Accuracy
1. Download the sample dataset for experimentation:
   ```bash
   wget https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBMSkillsNetwork-LX0117EN-Coursera/labs/synthetic_historical_fc_accuracy.tsv
   ```
2. Execute `weekly_stats.sh` to compute minimum and maximum absolute errors over the last seven entries. The script loads the recent values into an array, converts negatives to absolute values, and reports extremes.【d86971†L1-L29】
3. Replace tutorial artifacts in `weekly_stats.sh` and add error handling (e.g., file existence checks, array bounds validation) before production use.

## Operational Considerations
- **Data Quality:** Validate API responses for missing or malformed temperature values. Consider logging anomalies and skipping updates when data is incomplete.
- **Idempotency:** Guard `rx_poc.sh` against multiple executions within the same day by checking for an existing entry for the current date.
- **Security:** Store scripts in directories with restricted write access. Avoid exposing cron output logs with sensitive environment information.
- **Observability:** Implement health checks (e.g., verifying `rx_poc.log` growth) and alerts when daily ingestion fails.

## Repository Health Scan
A quick line-count scan shows that most scripts are placeholders (`basic.sh`, `rx_poc.sh`, `fc_accuracy.sh`), while only `weekly_stats.sh` contains logic—and even that script includes tutorial artifacts.【62e87d†L1-L6】【d86971†L1-L34】 To fully align the repository with the project brief, implement the ETL (`rx_poc.sh`), accuracy (`fc_accuracy.sh`), and supporting log initialization steps outlined above, and clean up `weekly_stats.sh`.

## Next Steps
1. Populate the empty scripts with the reference implementations provided in the exercise descriptions.
2. Add automated tests or linting (e.g., `shellcheck`) to validate Bash scripts.
3. Document operational runbooks and monitoring strategies once the pipeline is active.
4. Consider containerizing the workflow or using a scheduler such as Airflow for enterprise deployments.

## Authors
Adapted from course material by Jeff Grossman.
