WITH national_total AS (
    SELECT year, SUM(dwellings) AS dwellings
    FROM {{ ref('stg_ssb__boliger') }}
    WHERE region_code = '0'
    GROUP BY year
),
-- 2111 = Svalbard, not a kommune
-- 1901/1915 in 2013: SSB published on pre-merger codes (Harstad + Bjarkøy merged 2013-01-01)
known_gaps AS (
    SELECT year, SUM(dwellings) AS dwellings
    FROM {{ ref('stg_ssb__boliger') }}
    WHERE region_code = '2111'
        OR (region_code IN('1901', '1915') AND year = 2013)
    GROUP BY year
),

fact_total AS (
    SELECT year, SUM(dwellings) AS dwellings
    FROM {{ ref('fct_dwellings') }}
    GROUP BY year
),

expected AS (
    SELECT
        n.year,
        n.dwellings - coalesce(g.dwellings, 0) AS expected_dwellings
    FROM national_total AS n
    LEFT JOIN known_gaps AS g ON n.year = g.year
)

SELECT
    e.year,
    e.expected_dwellings,
    f.dwellings AS actual_dwellings,
    f.dwellings - e.expected_dwellings AS difference
FROM expected AS e
INNER JOIN fact_total AS f ON e.year = f.year
WHERE f.dwellings <> e.expected_dwellings