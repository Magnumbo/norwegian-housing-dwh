# 0002. Regular model instead of snapshot

Status: accepted
Date: 2026-08-28

## Context

The kommune geography is SCD2, they change code and border. We therefore need valid_from and valid_to to keep track.

## Decision

Build dim_geografi as a regular dbt-model with valid dates from Klass.

## Alternatives considered

dbt snapshots could serve the same purpose, but it only keeps track from the day it was implemented. We use data that contains changes going back in time, so snapshots would not capture them.

## Consequences

The model has to calculate valid_from/valid_to from the dates the different values change. We keep all the history going back in the data.
