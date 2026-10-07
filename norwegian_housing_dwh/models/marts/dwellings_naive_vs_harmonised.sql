WITH dwellings AS (
    SELECT * FROM {{ ref('fct_dwellings') }}
),

geography AS (
    SELECT * FROM {{ ref('dim_geography') }}
),

history AS (
    SELECT * FROM {{ ref('int_kommune_korrespondanse') }}
),

geography_dwellings AS (
    SELECT
        code,
        year,
        dwellings
    FROM geography AS g
    INNER JOIN dwellings AS d ON g.geography_key = d.geography_key
),

harmonised AS (
    SELECT
        current_code,
        year,
        SUM(dwellings) AS dwellings
    FROM geography_dwellings AS gd
    INNER JOIN history AS h ON gd.code = h.start_code
    GROUP BY current_code, year
),

naive AS (
    SELECT
        code,
        year,
        SUM(dwellings) AS dwellings
    FROM geography_dwellings
    GROUP BY code, year
)

SELECT
    h.current_code,
    h.year,
    n.dwellings as naive_dwellings,
    h.dwellings as harmonised_dwellings
FROM harmonised  AS h
LEFT JOIN naive n ON h.current_code = n.code AND h.year = n.year
