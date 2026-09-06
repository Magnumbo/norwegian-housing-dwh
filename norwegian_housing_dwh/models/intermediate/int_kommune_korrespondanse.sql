WITH RECURSIVE source_changes AS (
    SELECT * FROM {{ ref('stg_klass__kommune_endringer') }}
    WHERE old_code <> new_code
),
source_codes AS (
    SELECT * FROM {{ ref('stg_klass__kommune_koder') }}
),
walk AS (
    -- ANKER: startpunktet. Hver code, med seg selv som "hvor jeg er nå"
    SELECT DISTINCT code AS start_code, code AS current_code
    FROM source_codes

    UNION ALL

    -- REKURSJON: står jeg på en code som selv har en redirect, ta ett hopp til
    SELECT w.start_code, s.new_code
    FROM walk w
    JOIN source_changes s ON s.old_code = w.current_code
)
SELECT start_code, current_code
FROM walk
WHERE current_code NOT IN (SELECT old_code FROM source_changes)  -- enden: ingen flere hopp