WITH mart AS (
    SELECT
        year,
        SUM(harmonised_dwellings) AS harmonised_dwellings
    FROM {{ ref('dwellings_naive_vs_harmonised') }}
    GROUP BY year
),

fact AS (
    SELECT
        year,
        SUM(dwellings) AS dwellings
    FROM {{ ref('fct_dwellings') }}
    GROUP BY year
)

SELECT
    m.year,
    m.harmonised_dwellings,
    f.dwellings,
    m.harmonised_dwellings - f.dwellings AS dwellings_diff
FROM mart AS m
INNER JOIN fact AS f ON m.year = f.year
WHERE m.harmonised_dwellings <> f.dwellings

