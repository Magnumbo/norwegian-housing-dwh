WITH kommune_code AS (
    SELECT * FROM {{ ref('stg_klass__kommune_koder') }}
),

correspondence AS (
    SELECT * FROM {{ ref('int_kommune_korrespondanse') }}
),

area AS (
    SELECT * FROM {{ ref('int_kommune_area') }}
),

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
