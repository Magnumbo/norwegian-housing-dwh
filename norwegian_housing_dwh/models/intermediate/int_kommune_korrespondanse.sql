WITH RECURSIVE source_changes AS (
    SELECT * FROM {{ ref('stg_klass__kommune_endringer') }}
    WHERE old_code <> new_code
),
source_codes AS (
    SELECT * FROM {{ ref('stg_klass__kommune_koder') }}
),
walk AS (
    -- Anchor member: every code starts at itself
    SELECT DISTINCT code AS start_code, code AS current_code
    FROM source_codes

    UNION ALL

    -- Recursive member: if the current code has changed, follow it one hop
    SELECT w.start_code, s.new_code
    FROM walk w
    JOIN source_changes s ON s.old_code = w.current_code
)
SELECT start_code, current_code
FROM walk
-- Termination: keep the codes that never changed again. Assumes an old code no
-- longer exists, which does not hold for border adjustments (see ADR-0007)
WHERE current_code NOT IN (SELECT old_code FROM source_changes)
