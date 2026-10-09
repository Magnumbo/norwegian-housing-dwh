# 0005. Harmonise split kommuner into stable areas

Status: accepted
Date: 2026-10-07

## Context

For kommuner that were split, such as Ålesund (`1507`) into Ålesund (`1508`) and Haram (`1580`) in 2024, one historical code maps to multiple current codes. The links in Klass run through `1507`, so it is impossible to determine how many dwellings were in the former Haram during 2020–2023.

This caused double counting in the mart: both `1508` and `1580` received the full area’s figures through 2023, making Haram appear to fall from 33,764 dwellings to 4,644 in 2024. Also, a version that belongs to multiple of today's codes breaks the (code, valid_from) grain.

## Decision

Combine kommuner like Ålesund (`1508`) and Haram (`1580`) into one harmonised area, using the lowest kommune code for the entire period. The grouping follows entirely from Klass data with no values estimated, and nothing is counted twice. Kommuner get joined together when they have a common start-kommune. Store the kommune areas in int_kommune_area, and add area_code to dim_geography.

A version is joined to its area rather than to its current codes. All current codes from the same origin share one area, so 1507 → 1508 and 1507 → 1580 both become (1507, 1508), and DISTINCT collapses them into one row. This keeps the (code, valid_from) grain.

## Alternatives considered

One option is to **allocate the figures using weights**. The 2020–2023 figures for Ålesund (`1507`) could be divided between Ålesund (`1508`) and Haram (`1580`) using their shares in the first year after the split (86% and 14%). This would produce two separate series, but the figures before 2024 would be estimates rather than SSB figures.

Another option is to **bypass `1507` and trace the former municipalities directly**, assigning `1534` to `1580` and the remainder to `1508`. This would give the correct result, but Klass’s change records do not contain the information needed to do it. We would therefore have to encode that mapping manually, or find another source for it.

A separate t**bridge table** with one row per historical version and current municipality code would keep the dimension clean. It would still double count dwellings after a split when figures are summed by current code, however, and every query would need an additional join.

## Consequences

We get exact numbers and no estimates or dwellings double counted. Combined kommuner like Ålesund and Haram cannot however be shown separately before they split.

The grouping rule only looks one step: it assumes current codes sharing a start code never chain onwards to other areas. assert_kommune_area_is_closed fails if that ever stops holding.
