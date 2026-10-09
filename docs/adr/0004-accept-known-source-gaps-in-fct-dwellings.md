# 0004. Accept known source gaps in fct_dwellings

Status: accepted
Date: 2026-10-06

## Context

fct_dwellings uses a point-in-time INNER JOIN to dim_geography, which can make data disappear if one of the tables has values the other doesn't have. This join also removes rows that should be excluded, including the national total (code 0), county totals, and the zero values (0, not NULL) SSB supplies for code-and-year combinations in which a kommune did not exist.

The drawback is that rows without a match disappear without warning. Two discrepancies were found in the data. The first is Svalbard (2111). Svalbard is not a kommune and is therefore absent from Klass 131. The second is Harstad (1901) and Bjarkøy (1915) in 2013 (11,855 dwellings). Klass records their merger as effective from 1 January 2013, but table 06265 published the 2013 figures under the old codes. The changes in 2020 and 2024 are consistent.

## Decision

We document and keep track of the discrepancies in the test assert_fct_dwellings_reconciles_with_ssb_total. The test lists the known discrepancies and fails if any other rows go missing. Svalbard is kept out since it is not a kommune. Harstad 2013 is accepted as a known source gap, since it is only one kommune for one year.

## Alternatives considered

Add a dedicated row to the dimension, such as geography_key = '-1' and name = 'Unknown', rather than leave the key empty. Rows without a match point to that row instead of disappearing. This preserves the totals, and the not_null and relationships tests still pass. The drawback is that it does not solve the underlying problem, with Harstad’s 11,855 dwellings ending up under “Unknown” rather than Harstad.

A correction table was also considered, with a small CSV file in the repository (a seed in dbt) that records known source errors and how to correct them. It gives Harstad the correct historical series. However, it introduces a manual list that someone must maintain.

## Consequences

We do not get correct data for the source gaps in the problem years. However, by documenting and keeping track we can always change to the one of the two alternatives considered. Harstad gets a fall of 11,855 dwellings in 2013. By using the test we can detect new discrepancies.
