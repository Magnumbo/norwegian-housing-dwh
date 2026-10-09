WITH source_dwellings AS (
    SELECT * FROM {{ ref('stg_ssb__dwellings') }}
),

geography AS (
    SELECT * FROM {{ ref('dim_geography') }}
),

-- Municipality changes take effect on 1 January, so each year is matched to the
-- code version valid on that date
source_dwellings_year_as_date AS (
    SELECT
        *,
        make_date(year, 1, 1) AS year_date
    FROM source_dwellings
),

-- Inner join on purpose: it drops the national and county totals and the zero
-- rows for codes that did not exist that year. Rows lost for other reasons are
-- caught by assert_fct_dwellings_reconciles_with_ssb_total (ADR-0004).
-- valid_to is exclusive, and NULL for the version in use today.
source_with_keys AS (
    SELECT *
    FROM source_dwellings_year_as_date AS s
    INNER JOIN geography AS g
        ON s.region_code = g.code
        AND s.year_date >= g.valid_from
        AND s.year_date < coalesce(g.valid_to, DATE '9999-12-31')
)

SELECT geography_key, building_type_code, year, dwellings FROM source_with_keys
