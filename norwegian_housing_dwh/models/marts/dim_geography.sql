WITH kommune_code AS (
    SELECT * FROM {{ ref('stg_klass__kommune_codes') }}
),

correspondence AS (
    SELECT * FROM {{ ref('int_kommune_correspondence') }}
),

area AS (
    SELECT * FROM {{ ref('int_kommune_area') }}
),

-- A split code leads to several of today's codes, but they all share one area.
-- DISTINCT keeps one row per historical code, so the (code, valid_from) grain
-- holds (ADR-0005).
code_with_area AS (
    SELECT DISTINCT
        c.start_code,
        a.area_code,
        a.area_name
    FROM correspondence AS c
    INNER JOIN area AS a ON c.current_code = a.current_code
),

code_with_key AS (
    SELECT
        *,
        {{ dbt_utils.generate_surrogate_key(['code', 'valid_from']) }} AS geography_key
    FROM kommune_code
),

-- Left join so a code without an area stays in the dimension and fails the
-- not_null test on area_code, instead of disappearing silently
code_key_area AS (
    SELECT
        k.*,
        a.area_code,
        a.area_name
    FROM code_with_key AS k
    LEFT JOIN code_with_area AS a ON k.code = a.start_code
)

SELECT
    geography_key,
    code,
    area_code,
    area_name,
    name,
    valid_from,
    valid_to,
    is_current
FROM code_key_area
