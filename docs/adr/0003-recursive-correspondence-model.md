# 0003. Recursive correspondence model for historical-to-current codes

Status: accepted
Date: 2026-09-06

## Context

To harmonise the dwelling fact across boundary changes we need to map any
historical kommune code onto today's geography. Klass `/changes` gives only
*one-hop* edges (`old_code → new_code`), but a code can move several times
(`1534 → 1507 → 1580`), so a single hop is not enough. Some `/changes` rows are
name-only changes where `old_code = new_code` (e.g. Trondheim → "Trondheim -
Tråante"). The resolution logic is complex and reused downstream, so per
`staging → intermediate → marts` layering it belongs in an intermediate model,
not the dimension or the mart.

## Decision

Build `int_kommune_korrespondanse` as a **recursive CTE** that traverses the
change edges. The anchor comes from the full code list (`stg_klass__kommune_koder`)
so every code — including ones that never changed — starts as a row mapping to
itself. The recursive member follows `old_code = current_code → new_code` until it
reaches a code that is never an `old_code` (a terminal, current code). Name-only
edges (`old_code = new_code`) are filtered out in the model, because they are
self-loops that never terminate. Grain is `(start_code, current_code)`, tested
with `unique_combination_of_columns`. Materialised as a `view`.

Splits are kept as **one-to-many** rows (`1507 → {1508, 1580}`) — the truthful
correspondence. The double-counting that this creates is a *mart* concern, not a
concern of this pure geography map.

## Alternatives considered

- **A fixed number of self-joins** instead of recursion — rejected; recursion is
  cleaner and Databricks SQL supports `WITH RECURSIVE` (confirmed empirically).
- **Solving double-counting inside the correspondence** (weights, or dropping the
  split) — rejected; that mixes measure policy into a geography lookup, the wrong
  layer. The map states the truth; the mart applies the policy.
- **Hand-building the mapping** — rejected per project principle; pull it from
  Klass so it is empirical and reproducible.

## Consequences

- A small, queryable, testable geography lookup; splits are visible and honest.
- Correctness depends on two things staying true: `WITH RECURSIVE` support, and
  the self-loop filter. Both are load-bearing — a longer cycle (A→B→A) would
  reintroduce non-termination, so termination is a property to watch.
- The double-counting for splits is deferred and MUST be handled in the mart.
- The `is_current` flag from `koder` is available to cross-check terminals as a
  future test (terminal ⇔ `is_current`), turning the redundancy into a contract.
