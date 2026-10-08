# Databricks notebook source
"""Load the raw SSB files in the Volume into bronze Delta tables.

Step 2 of the pipeline: notebooks/ingest writes the API responses to the Volume,
this notebook turns each file into a table, and dbt builds on the tables. Every
run overwrites the tables with the files as they are now.
"""

import itertools
import json

# Databricks injects `spark` into notebooks; importing it makes that explicit,
# so ruff and editors know where it comes from.
from databricks.sdk.runtime import spark
from pyspark.sql import functions as F
from pyspark.sql.types import LongType, StringType, StructField, StructType

VOLUME = "/Volumes/nor_housing/bronze/ssb"
SCHEMA = "nor_housing.bronze"

# COMMAND ----------


def load_jsonstat(table_id: str) -> None:
    """Unpack an SSB JSON-stat table into one row per cell and save it.

    JSON-stat stores a cube: a list of dimensions and one flat list of values,
    ordered with the last dimension varying fastest. itertools.product walks the
    dimensions in the same order, so pairing the two gives every value its labels.

    Args:
        table_id (str): SSB table id, e.g. "06265". Read from
            <VOLUME>/<table_id>.json, written to <SCHEMA>.raw_<table_id>.

    Raises:
        ValueError: If the number of values does not match the number of
            dimension combinations, i.e. SSB changed the shape of the response.
    """
    with open(f"{VOLUME}/{table_id}.json", encoding="utf-8") as f:
        data = json.load(f)

    # Each dimension's codes, in the position order SSB gives them
    axes = []
    for name in data["id"]:
        index = data["dimension"][name]["category"]["index"]
        axes.append(sorted(index, key=index.get))

    rows = [
        (*labels, value)
        for labels, value in zip(itertools.product(*axes), data["value"], strict=True)
    ]

    schema = StructType(
        [StructField(name.lower(), StringType()) for name in data["id"]]
        + [StructField("value", LongType())]
    )
    df = spark.createDataFrame(rows, schema=schema)
    df.write.mode("overwrite").saveAsTable(f"{SCHEMA}.raw_{table_id}")


def load_klass(file_name: str, list_field: str, table_name: str) -> None:
    """Explode a Klass response into one row per record and save it.

    A Klass response is already a list of records under one top-level field, so
    Spark can read it directly.

    Args:
        file_name (str): File in the Volume, e.g. "131_codes.json".
        list_field (str): Top-level field holding the records, e.g. "codes".
        table_name (str): Bronze table to overwrite, without the schema.
    """
    df = (
        spark.read.option("multiline", "true")
        .json(f"{VOLUME}/{file_name}")
        .select(F.explode(list_field).alias("record"))
        .select("record.*")
    )
    df.write.mode("overwrite").saveAsTable(f"{SCHEMA}.{table_name}")


# COMMAND ----------

load_jsonstat("06265")
load_klass("131_changes.json", "codeChanges", "raw_131_changes")
load_klass("131_codes.json", "codes", "raw_131_codes")
