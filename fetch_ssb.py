"""Ingest SSB StatBank tables into the local raw layer."""

import argparse
from pathlib import Path

import requests


def fetch_data_ssb(table_id: str) -> None:
    """Fetch a table from SSB and write the raw JSON-stat response to disk.

    The response body is saved untouched to data/raw/<table_id>.json.

    Args:
        table_id (str): SSB table id, e.g. "06265".

    Raises:
        requests.HTTPError: If SSB responds with a 4xx/5xx status.
    """
    r = requests.get(
        f"https://data.ssb.no/api/pxwebapi/v2/tables/{table_id}/data?lang=no",
        timeout=10,
    )
    r.raise_for_status()

    Path("data/raw").mkdir(parents=True, exist_ok=True)

    with open(f"data/raw/{table_id}.json", "w", encoding="utf-8") as f:
        f.write(r.text)


def main() -> None:
    """Fetch a single SSB table into the raw layer."""
    parser = argparse.ArgumentParser(description="Ingest an SSB table.")
    parser.add_argument("table_id", help='SSB table id, e.g. "06265"')
    args = parser.parse_args()
    fetch_data_ssb(args.table_id)


if __name__ == "__main__":
    main()
