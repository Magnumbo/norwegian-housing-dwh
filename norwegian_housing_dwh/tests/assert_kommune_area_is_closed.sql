-- Fails if a historical code belongs to more than one stable area. Areas are
-- grouped in one step in int_kommune_area; a longer chain of splits would break
-- that (ADR-0005).
WITH correspondence AS (
    SELECT * FROM {{ ref('int_kommune_correspondence') }}
),

area AS (
    SELECT * FROM {{ ref('int_kommune_area') }}
),

areas_per_start_code AS (
    SELECT
        c.start_code,
        COUNT(DISTINCT a.area_code) AS count_areas
    FROM correspondence AS c
    INNER JOIN area AS a ON c.current_code = a.current_code
    GROUP BY c.start_code
)

SELECT
    start_code,
    count_areas
FROM areas_per_start_code
WHERE count_areas > 1
