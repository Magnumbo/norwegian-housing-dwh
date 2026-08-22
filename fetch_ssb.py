"""Ingest SSB StatBank tables into the local raw layer."""

import argparse
from pathlib import Path

import requests


def fetch_data_ssb(
    table_id: str, out_dir: str = "data/raw", parameters: dict[str, str] | None = None
) -> None:
    """Fetch a table from SSB and write the raw JSON-stat response to disk.

    The response body is saved untouched to <out_dir>/<table_id>.json.

    Args:
        table_id (str): SSB table id, e.g. "06265".
        out_dir (str): Directory for the raw SSB table data.
        parameters (dict): Query parameters for modifying the data range, e.g.
            Tid: 2020-2026.

    Raises:
        requests.HTTPError: If SSB responds with a 4xx/5xx status.
    """
    parameters = parameters or {}

    r = requests.get(
        f"https://data.ssb.no/api/pxwebapi/v2/tables/{table_id}/data?lang=no",
        params=parameters,
        timeout=10,
    )
    r.raise_for_status()

    out_path = Path(out_dir)
    if not out_path.exists():
        out_path.mkdir(parents=True)

    with open(out_path / f"{table_id}.json", "w", encoding="utf-8") as f:
        f.write(r.text)


def main() -> None:
    """Fetch a single SSB table into the raw layer."""
    parser = argparse.ArgumentParser(description="Ingest an SSB table.")
    parser.add_argument("table_id", help='SSB table id, e.g. "06265"')
    parser.add_argument(
        "--out-dir",
        default="data/raw",
        type=str,
        help="directory for the raw SSB table data",
    )
    parser.add_argument(
        "--params",
        action="append",
        metavar="KEY=VALUE",
        default=None,
        type=str,
        help="Query parameters for modifying the data range, e.g. Tid: 2020-2026",
    )
    args = parser.parse_args()

    parameters = {}
    for pair in args.params or []:
        key, value = pair.split("=", 1)
        parameters[key] = value

    fetch_data_ssb(args.table_id, args.out_dir, parameters)


if __name__ == "__main__":
    main()
