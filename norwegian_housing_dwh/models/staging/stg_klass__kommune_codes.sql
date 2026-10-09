WITH source AS (
    SELECT * FROM {{ source('klass', 'raw_131_codes') }}
),

renamed AS (
    SELECT
        code,
        name,
        -- Validity clipped to the requested range (from 2006), the span of the
        -- dwelling data. Klass leaves valid_to empty for codes still in use.
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
