# 0006. End the Klass change window before the 2026 border adjustment

Status: accepted
Date: 2026-10-09

## Context

On 1 January 2026 the borders between Nordre Follo (3207), Vestby (3216) and Indre Østfold (3118) changed how the border between them is drawn. This change made it so some dwellings moved from Indre Østfold to the two other kommuner. In the Klass history this is marked as 3118 → 3216, 3118 → 3207. Our program assumes that when a code is an old_code, it no longer exists. Indre Østfold will therefore no longer be included.

## Decision

Fetch the list of kommune changes from Klass only up to the border change (to=2026-01-01, which is exclusive). All dwelling data, including 2026 for the three kommuner, is still loaded. The model just does not know that some dwellings moved.

## Alternatives considered

If we run the program for 2026, Indre Østfold disappears and its dwellings end up under Nordre Follo and Vestby, without any test failing.

A larger rewrite of the code to account for cases where borders change, but no kommuner are merged or split is also a solution. Then we get a combined history for the three kommuner as per 0005, just because a couple of dwellings of a pool of about 57,000 dwellings moved.

## Consequences

With a Klass change list of before 2026, the warehouse pretends that the border change did not happen. The dwelling figures are SSB's own, but the series for the three kommuner have a small break in 2026, as a few dwellings moved between them. Later kommune changes are also left out until the date is moved by hand, and the new window must then be checked for border adjustments like this one.
