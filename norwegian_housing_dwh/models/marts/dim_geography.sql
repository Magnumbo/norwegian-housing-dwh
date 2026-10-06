WITH source AS (
    SELECT * FROM {{ ref('stg_klass__kommune_koder') }}
),

code_with_key AS (
    SELECT
        *,
        {{ dbt_utils.generate_surrogate_key(['code', 'valid_from']) }} AS geography_key
    FROM source
)
SELECT
    geography_key,
    code,
    name,
    valid_from,
    valid_to,
    is_current
FROM code_with_key