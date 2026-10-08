# Databricks notebook source
"""Fetch the raw SSB data into the Volume.

Step 1 of the pipeline: call the SSB APIs and write each response untouched to the
Volume. notebooks/load_bronze then turns the files into bronze tables.
"""

from fetch_klass import fetch_klass_ssb_changes, fetch_klass_ssb_codes
from fetch_ssb import fetch_data_ssb

VOLUME = "/Volumes/nor_housing/bronze/ssb"

# Table 06265 starts in 2006, so the municipality history starts there too
START_DATE = "2006-01-01"
# Exclusive end date for the change list. It stops before the 2026-01-01 boundary
# adjustment, where parts of Indre Østfold (3118) moved to Nordre Follo and Vestby
# while 3118 lived on: the correspondence model assumes an old code stops
# existing, so including that change would resolve 3118 away.
CHANGES_END_DATE = "2026-01-01"
KOMMUNE_CLASSIFICATION = "131"

# COMMAND ----------

# Dwelling stock: every value of every dimension
fetch_data_ssb(
    "06265",
    out_dir=VOLUME,
    parameters={
        "valueCodes[Region]": "*",
        "valueCodes[BygnType]": "*",
        "valueCodes[ContentsCode]": "*",
        "valueCodes[Tid]": "*",
    },
)

# COMMAND ----------

# Municipality changes and code versions
fetch_klass_ssb_changes(
    KOMMUNE_CLASSIFICATION, START_DATE, CHANGES_END_DATE, out_dir=VOLUME
)
fetch_klass_ssb_codes(KOMMUNE_CLASSIFICATION, START_DATE, out_dir=VOLUME)
