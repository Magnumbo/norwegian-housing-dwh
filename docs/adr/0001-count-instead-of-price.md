# 0001. Count instead of price

Status: accepted
Date: 2026-08-27

## Context

SSB does not publish price per m2 on a kommune-level, only for fylke/nation wide.

## Decision

We use the count of dwellings as a value we look at when kommuner merges or splits. Count can be added together.

## Alternatives considered

When we want to look at how the data for houses changes for kommuner, we could look at how the price per m2 changes. We cannot use this value as it is not available for kommuner. Also, if it ever becomes available, it is not easy to say how the price should change when kommuner are merged. For instance, what happens when a kommune with low price per m2 with few dwellings merge with a kommune with high price per m2 with many dwellings.

## Consequences

Choosing the count makes it easier to decide what will happen when kommuner merges, as we just add the number of dwellings together. By not choosing price per m2, we do not get information about how the price changes when kommuner merges.
