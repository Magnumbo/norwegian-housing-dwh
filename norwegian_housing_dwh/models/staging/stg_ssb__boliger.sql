WITH source AS (
    SELECT * FROM {{ source('ssb', 'raw_06265') }}
),

renamed AS (
    SELECT
        region       AS region_code,
        bygntype     AS building_type_code,
        contentscode AS contentscode_code,
        cast(tid as int) AS year,
        value        AS dwellings
    FROM source
)

SELECT * FROM renamed