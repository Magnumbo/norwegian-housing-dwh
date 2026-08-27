WITH source AS (
    SELECT * FROM {{ source('klass', 'raw_131_changes') }}
),

renamed AS (
    SELECT
        cast(changeOccurred AS date) AS change_date,
        oldCode                      AS old_code,
        oldName                      AS old_name,
        newCode                      AS new_code,
        newName                      AS new_name
    FROM source
)

SELECT * FROM renamed