# CLAUDE.md

Guidance for Claude Code when working in this repository.

> This is the instruction file Claude Code reads at the start of every session.
> It is published as part of the project's AI-use declaration (see the README),
> lightly edited to remove personal notes. Session notes are kept locally and not
> published.

## What this project is

A small but real **data warehouse on Norwegian public data**. It ingests housing
data from Statistics Norway's open API (SSB PxWebApi, no key required), loads it
into Databricks, and models it with dbt into a dimensional star schema.

**The real problem it solves.** Municipal boundaries in Norway keep changing, and
that breaks time series. 119 municipalities became 47 in 2020, and 114 got new
numbers in 2024 (e.g. Ålesund was split back into Ålesund and Haram). So a plain
question like "how has the housing stock grown since 2006 in the area that is now
Ålesund?" cannot be answered directly — you must stitch old and new municipality
codes together, track who became whom and when, and avoid double-counting. This
warehouse normalises everything onto one consistent geography so trends are
actually comparable across the boundary changes. The tagline: *history that does
not break when the map changes.*

This is the signature feature and the reason the project exists — not a dbt demo
with housing numbers on top.

## Goals (equally weighted)

1. **Magnus learns modern data engineering properly** — dbt, dimensional
   modelling, SCD type 2, orchestration and CI are all new to him. The process
   matters as much as the result. Understanding *why* each tool behaves as it
   does is an explicit goal, not a nice-to-have.
2. **A finished, verifiable project** that actually runs end-to-end. A complete
   small thing beats an impressive half-built one.
3. **A public portfolio project** for data engineering roles, covering dbt, a
   cloud warehouse, dimensional modelling, orchestration and CI.

## How to work with Magnus

**Claude is a navigator/mentor, not a coder.** Magnus is in the driver's seat. If
Claude writes his implementation code and config, then Claude did the project, not
Magnus. The pattern is: _explain the concept, give a short illustrative example
(not his exact code), let Magnus write it himself._

- **Reply in Norwegian.** Code, comments, docstrings and documentation in English.
- **One step at a time.** Name what comes next in a line or two so he sees the
  shape, but do not spell out commands, file contents or gotchas for steps he has
  not reached — they go stale and bury the step he is actually on.
- **Reviewing his work is part of the current step.** Point out what needs fixing
  before he moves on, then stop at that boundary.
- **Do not download files or fetch external resources for him.** Say where a thing
  lives, hand him the command, let him run it.
- He will ask for hints and "does this look right?" mid-task. Answer those, and
  ask questions that lead him to the answer rather than handing him the answer.
- **Verifying data and assumptions yourself is encouraged and expected** — but the
  implementation is his. SSB fields, table shapes and municipality-change data
  should be checked against reality before building on them.
- **Teach engineering craft continuously and unprompted** — naming, SQL and dbt
  idioms, model layering (staging → intermediate → marts), tests as contracts,
  when a dbt snapshot fits and when it does not. Name the idiomatic
  choice and say why. Magnus should never have to ask for it.

### Getting-it-done and understanding are equally important

Ship *and* understand. Three mechanisms:

1. **Teach-back at every phase boundary.** Before moving on, Magnus explains in
   his own words what we built and why. Do not proceed until it holds; if it does
   not, that is a signal the explanation was too thin, not that he failed.
2. **A decision log he writes** (`docs/adr/`) — what he chose, why, and what he
   rejected.
3. **Explain the *why*, not just the *what*** — especially for dbt and dimensional
   modelling, where the "why" is the whole point.

## The stack, and why

T-shaped by design: go **deeper in Databricks** (which he already knows for
PySpark/medallion ETL) rather than spreading to a fourth platform. The new ground
is the SQL/warehouse/dbt side of Databricks, not the Spark-notebook side he knows.

| Layer | Tool | Why |
| --- | --- | --- |
| Ingestion | Python + SSB PxWebApi | Public, recognisable data; no key |
| Warehouse | Databricks Free Edition (Delta Lake / Databricks SQL / Unity Catalog) | Real cloud warehouse; deepens existing skill |
| Transformation | dbt (`dbt-databricks`) | Software discipline on SQL |
| Modelling | Star schema + SCD type 2 | Dimensional modelling vs 3NF; solves the kommune problem |
| Orchestration | Databricks Workflows | Real orchestration (deps, retries, lineage) vs cron |
| CI | GitHub Actions running `dbt build` | Tests run on every push, not only locally |

The portable skills here — dbt, dimensional modelling, SCD2, CI — are **not**
Databricks-specific and transfer to BigQuery, Snowflake or Fabric.

## Roadmap — walking skeleton first

Get the whole chain hanging together end-to-end fast, then deepen on a running
system instead of building a house of cards that only stands at the end.

- **Phase 0** — empty repo, CLAUDE.md, venv, Databricks account. *(done)*
- **Phase 1** — one SSB table (06265, dwelling stock per municipality) → raw data
  in Databricks. *(done)*
- **Phase 2** — dbt connected to Databricks, one staging model, one test. The
  chain now *works* end to end. *(done)*
- **Phase 3** — star schema + SCD2 for the municipality changes. The heart of it.
  *(done)*
  - *The demonstrator mart:* a small analysis mart that **demonstrates** the
    signature feature by contrasting two time series for the same area — a
    *naive* series on raw kommune codes (which breaks at a boundary change)
    against a *harmonised* series built on the SCD2 dimension (continuous through
    the change). Because the fact is a **count** (dwellings), the harmonised
    series is built by **summing** the constituent old municipalities onto the
    target geography — the trap is double-counting, not non-additivity (see
    Known facts). It lives as a dbt **mart model** (versioned, tested, part of
    the star schema), not a loose notebook; any figure on top is presentation.
- **Phase 4** — Databricks Workflows orchestration + GitHub Actions CI.

Scope discipline: **one fact table** (dwelling stock per municipality, SSB 06265),
a handful of dimensions, SCD2 on geography as the signature feature. Resist scope
creep actively.

## Known facts and caveats (verify before contradicting)

- **SSB PxWebApi** is open, no registration. Version 2 (from Oct 2025) supports
  HTTP GET; base lives under `data.ssb.no`. Output is JSON-stat 1.2 or CSV.
- **The fact is SSB table 06265** — "Boliger, etter bygningstype", dwelling stock
  per municipality, annual **2006–2025**, at kommune level (`(K)`). Chosen and
  verified 2026-08-21. This is the grain that lets the signature feature be shown
  across *both* the 2020 and 2024 boundary changes. Its variables are Region,
  Bygningstype, ContentsCode and Tid — confirm them against the live metadata
  endpoint before building staging (Phase 2); do not assume field names.
- **Why a count and not price:** SSB does **not** publish square-metre price at
  kommune level over time. Kommune-level price (tables 14310/14545) starts in 2025
  only; every historical price series is national (07240/07241), fylke (03364 /
  03637 / 06695) or landsdel index (07221/07230). A price series that crosses a
  boundary change simply does not exist at kommune grain in StatBank — third
  parties (datakart.no, kommuneprofilen.no) derive it from SSB microdata, which is
  a separate project and loses SSB as a clean citable source. Verified by an
  exhaustive table search 2026-08-21. **Optional enrichment:** table 14545 offers a
  2025 kommune price snapshot that can hang off the geography dimension as a
  current-level attribute — never pretend it has history.
- **Municipality changes** are the core data problem: 2020 (119→47, down to 356
  municipalities) and 2024 (114 new numbers; Ålesund split into Ålesund + Haram).
  SSB publishes the change/correspondence data (SSB Klass classification API and
  the "Alle endringer i de regionale inndelingene" resource) — that mapping is
  what feeds the SCD2 dimension.
- **Do not hand-build the municipality-change mapping — pull it from the SSB Klass
  API.** Klass already exposes exactly what the SCD2 dimension needs: the code set
  as it was on a given date, the changes within a time range, and correspondence
  tables mapping one municipality version to another. Feed `dim_geography` from
  Klass rather than hardcoding "Haram → Ålesund → Haram". Empirical, robust, and a
  better story. (Confirmed via research 2026-08-19.)
- **Dwelling counts ARE additive — that is why this fact works.** When
  municipalities merge you can **sum** their dwelling counts onto the harmonised
  geography; the academic "boundary-consistent time series" methods (Netherlands,
  Czech Republic, Spain) harmonise *population* for exactly this reason — counts
  are additive. The real trap is **double-counting**, not non-additivity. This is
  the deliberate reason a count was chosen over a price: a price index / price per
  m² cannot be summed and would need **weighting** (by dwellings or transactions),
  the harder path the project sidesteps. Keep this rationale in the decision log.
  (Design decision 2026-08-21; research 2026-08-19.)
- **Databricks outbound internet works** (confirmed 2026-08-22: SSB reachable from
  Databricks compute, HTTP 200), so the ingest runs *inside* Databricks rather than
  ingesting locally and uploading. `fetch_ssb.py` is pulled in as a Databricks **Git
  folder** and run there, writing the raw JSON-stat straight to a Unity Catalog
  Volume. SSB needs no API key, so no Databricks Secrets — but keep the `timeout=`
  habit on every outbound request.
  - **Raw landing location:** catalog `nor_housing`, schema `bronze`, volume `ssb`
    → `/Volumes/nor_housing/bronze/ssb/<table_id>.json`. A dedicated catalog keeps
    the project isolated from other work in the workspace.
- **Orchestration:** Databricks Workflows is real orchestration and enough for
  the project. Airflow/Dagster and dashboards/analysis are **out of scope** — the
  project ends with Phase 4; analysis on top of the data belongs in a separate
  project.

## References worth studying (prior art)

Nobody builds this exact project (SSB housing + Databricks + dbt + SCD2 on
municipalities), so it is differentiated — but every piece is well-trodden.
Study these for approach and structure; do not copy.

**SSB data and tooling**
- SSB PxWebApi v2 user guide — https://www.ssb.no/api/pxwebapiv2
- SSB Klass (classifications, changes, correspondence tables) —
  https://www.ssb.no/metadata/om-klass ·
  API: https://data.ssb.no/api/klass/v1/classifications/search?query=kommuner
- Official Python API examples (NO/EN) —
  https://github.com/janbrus/ssb-api-python-examples
- Statistics Norway on GitHub (incl. `ssb-sgis` GIS helpers, `ssb-mcp`) —
  https://github.com/statisticsnorway

**Boundary-consistent time series (the method behind the SCD2 harmonisation)**
- Netherlands, population time series across boundary changes —
  https://pubmed.ncbi.nlm.nih.gov/23336364/
- Czech Republic, "a universal" municipality dataset over time —
  https://www.mdpi.com/2306-5729/5/4/107

**dbt / modern-data-stack structure to imitate**
- awesome-public-dbt-projects (project layouts, staging→marts) —
  https://github.com/InfuseAI/awesome-public-dbt-projects
- dbt-duckdb — lets the whole dbt layer run locally on a laptop —
  https://github.com/duckdb/dbt-duckdb
- Modern Data Stack in a Box (DuckDB) —
  https://duckdb.org/2022/10/12/modern-data-stack-in-a-box

## Conventions

- **Python style:** PEP 8 via ruff. Run `ruff format` before committing; keep
  formatting-only changes in their own commit.
- **dbt:** layered models (staging → intermediate → marts); tests as contracts,
  not decoration; document sources with freshness.
- **Commit messages:** light Conventional Commits — `type(scope): imperative
  summary, lowercase, no full stop`; types `feat|fix|refactor|docs|chore|style`;
  English. **Never add `Co-Authored-By: Claude`** — Magnus writes the code, so
  crediting Claude would misrepresent authorship. Propose a draft, let him polish.
- **Data files are gitignored.** Never commit downloaded SSB extracts or
  credentials; keep secrets out of the repo.
