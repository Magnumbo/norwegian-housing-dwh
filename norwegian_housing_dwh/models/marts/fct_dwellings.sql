WITH source_dwellings AS (
    SELECT * FROM {{ ref('stg_ssb__boliger') }}
),

geography AS (
    SELECT * FROM {{ ref('dim_geography') }}
),

source_dwellings_year_as_date AS (
    SELECT
        *,
        make_date(year, 1, 1) AS year_date
    FROM source_dwellings
),

source_with_keys AS (
    SELECT *
    FROM source_dwellings_year_as_date AS s
    INNER JOIN geography AS g
        ON s.region_code = g.code
        AND s.year_date >= g.valid_from
        AND s.year_date < coalesce(g.valid_to, DATE '9999-12-31')
)

SELECT geography_key, building_type_code, year, dwellings FROM source_with_keys