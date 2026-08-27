"""Fetch SSB klassifications (Klass)."""

import argparse
from pathlib import Path

import requests


def fetch_klass_ssb_changes(
    classification_id: str,
    from_date: str,
    to_date: str,
    out_dir: str = "data/raw",
    parameters: dict[str, str] | None = None,
) -> None:
    """Fetch klass from SSB for a given Klass and write JSON response to disk.

    The response body is saved untouched to <out_dir>/<classification_id>_changes.json.

    Args:
        classification_id (str): id for the classification, e.g. "131".
        from_date (str): date the data range starts from.
        to_date (str): date the data range goes to.
        out_dir (str): Directory for the raw SSB table data.
        parameters (dict): Query parameters for modifying the data range, e.g.
            validFrom: "2014-01-01".

    Raises:
        requests.HTTPError: If SSB responds with a 4xx/5xx status.
    """
    parameters = parameters or {}

    r = requests.get(
        f"https://data.ssb.no/api/klass/v1/classifications/{classification_id}/changes",
        params={"from": from_date, "to": to_date, **parameters},
        timeout=10,
    )
    r.raise_for_status()

    out_path = Path(out_dir)
    if not out_path.exists():
        out_path.mkdir(parents=True)

    with open(
        out_path / f"{classification_id}_changes.json", "w", encoding="utf-8"
    ) as f:
        f.write(r.text)


def main() -> None:
    """Fetch a single SSB Klass."""
    parser = argparse.ArgumentParser(description="Ingest an SSB Klass.")
    parser.add_argument("classification_id", help='SSB classification id, e.g. "131"')
    parser.add_argument("from_date", help="date the data range starts from.")
    parser.add_argument("to_date", help="date the data range goes to.")
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
        help="Query params for modifying the data range.",
    )
    args = parser.parse_args()

    parameters = {}
    for pair in args.params or []:
        key, value = pair.split("=", 1)
        parameters[key] = value

    fetch_klass_ssb_changes(
        args.classification_id, args.from_date, args.to_date, args.out_dir, parameters
    )


if __name__ == "__main__":
    main()
