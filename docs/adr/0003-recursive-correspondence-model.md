# 0003. Recursive correspondence model for historical-to-current codes

Status: accepted
Date: 2026-09-06

## Context

To show how the different kommuner merge and split, we need a way to look up an old code, and see what code it belongs to today. Klass gives only one-hop edges from old_code to new_code, but a code can move several times e.g. 1534 → 1507 → 1580. Also, some changes don't give a new code, e.g. when a kommune changes its name.

## Decision

Create int_kommune_correspondence that traverses the code history with a recursive CTE. The model follows old_code → new_code until it reaches a code that is never an old_code. This is an end to the history, and is the current code used today. Kommuner that only change name where old_code = new_code are filtered out in the model, because they are self-loops that never terminate.

Splits are kept as one-to-many rows (1507 → {1508, 1580}).

## Alternatives considered

- **A fixed number of self-joins**, instead of recursion. We choose recursion as it is
  cleaner and Databricks SQL supports WITH RECURSIVE.
- **Solving double-counting inside the correspondence** with weights, or dropping splits. Rejected as that mixes measure policy into a geography lookup.
- **Hand-building the mapping**. Rejected as we want to do as little manual work as possible to avoid manually having to keep track of changes and remember to check and implement them.

## Consequences

A small, queryable, testable geography lookup. Correctness depends on two things staying true, WITH RECURSIVE support, and the self-loop filter. We would get non-termination if we get a cycle like A→B→A.

The double-counting for splits must be handled in the mart.
