# 0004. Surrogate key for dim_geography

Status: accepted
Date: 2026-09-07

## Context

`dim_geography` is an SCD2 dimension: grain is one row per code-version,
`(code, valid_from)`, so a single code (e.g. Trondheim 5001) has several rows.
A fact row knows only `(code, year)` and must point at the _right version_ — the
one whose validity window `[valid_from, valid_to)` contains the year. Something
has to carry that resolved pointer.

## Decision

Give `dim_geography` a surrogate key `geography_key`, built with
`{{ dbt_utils.generate_surrogate_key(['code', 'valid_from']) }}` — a deterministic
hash of the grain columns. The fact resolves the range match once, at fact-build
time, and stores `geography_key` as a single-column foreign key. All downstream
joins are then a plain equality: `fct.geography_key = dim.geography_key`.

## Alternatives considered

- **Composite natural key `(code, valid_from)`** — legitimate and gives the same
  "resolve the range once" benefit; rejected because the surrogate is a single
  join column instead of two, insulates the fact from changes in the natural key's
  shape, and is the recognised star-schema idiom (a CV goal for this project).
- **Range-joining live in every query** (`fct.code = dim.code AND fct.year BETWEEN
dim.valid_from AND dim.valid_to`) — rejected; repeats heavy, easy-to-get-wrong
  range logic on every read instead of resolving it once.

## Consequences

- One clean FK column; simple equality joins; standard dimensional idiom.
- The key is not human-readable (a hash, not "Trondheim 2018") — inspection still
  goes via `code`/`name`/`valid_from`, which stay on the row.
- The range resolution moves to fact-build; `dim_geography` just needs to expose a
  stable `geography_key` per version.
