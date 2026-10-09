WITH correspondence AS (
    SELECT * FROM {{ ref('int_kommune_korrespondanse') }}
),

code_names AS (
    SELECT
        code,
        name
    FROM {{ ref('stg_klass__kommune_koder') }}
    WHERE is_current
),

code_pairs AS (
    SELECT
        c1.current_code AS current_code_1,
        c2.current_code AS current_code_2
    FROM correspondence AS c1
    INNER JOIN correspondence AS c2 ON c1.start_code = c2.start_code
),

area AS (
    SELECT
        current_code_1 AS current_code,
        MIN(current_code_2) AS area_code
    FROM code_pairs
    GROUP BY current_code_1
),

area_names AS (
    SELECT
        a.area_code,
        array_join(array_sort(collect_list(c.name)), ' + ') AS area_name
    FROM area AS a
    INNER JOIN code_names AS c ON a.current_code = c.code
    GROUP BY a.area_code
)

SELECT
    a.current_code,
    a.area_code,
    n.area_name
FROM area AS a
INNER JOIN area_names AS n ON a.area_code = n.area_code
