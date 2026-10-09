WITH source AS (
    SELECT * FROM {{ source('klass', 'raw_131_codes') }}
),

renamed AS (
    SELECT
        code,
        name,
        cast(validFromInRequestedRange AS date) AS valid_from,
        cast(validToInRequestedRange AS date) AS valid_to
    FROM source
),

flagged AS (
    SELECT
        *,
        (valid_to IS NULL) AS is_current
    FROM renamed
)

SELECT * FROM flagged
