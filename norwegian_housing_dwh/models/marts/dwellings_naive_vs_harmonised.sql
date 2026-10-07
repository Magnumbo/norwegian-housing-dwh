WITH dwellings AS (
    SELECT * FROM {{ ref('fct_dwellings') }}
),

geography AS (
    SELECT * FROM {{ ref('dim_geography') }}
),

area AS (
    SELECT * FROM {{ ref('int_kommune_area') }}
),

geography_dwellings AS (
    SELECT
        code,
        year,
        dwellings,
        area_code
    FROM geography AS g
    INNER JOIN dwellings AS d ON g.geography_key = d.geography_key
),

harmonised AS (
    SELECT
        area_code,
        year,
        SUM(dwellings) AS dwellings
    FROM geography_dwellings
    GROUP BY area_code, year
),

naive AS (
    SELECT
        gd.area_code,
        gd.year,
        SUM(gd.dwellings) AS dwellings
    FROM geography_dwellings AS gd
    INNER JOIN area AS a ON gd.code = a.current_code
    GROUP BY gd.area_code, gd.year
)

SELECT
    h.area_code,
    h.year,
    n.dwellings AS naive_dwellings,
    h.dwellings AS harmonised_dwellings
FROM harmonised AS h
LEFT JOIN naive AS n ON h.area_code = n.area_code AND h.year = n.year
