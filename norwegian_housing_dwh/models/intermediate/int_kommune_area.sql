WITH korrespondanse AS (
    SELECT * FROM {{ ref('int_kommune_korrespondanse') }}
),

code_pairs AS (
    SELECT 
        k1.current_code AS current_code_1,
        k2.current_code AS current_code_2
    FROM korrespondanse AS k1
    INNER JOIN korrespondanse AS k2 ON k1.start_code = k2.start_code
)

SELECT 
    current_code_1 AS current_code,
    MIN(current_code_2) AS area_code
FROM code_pairs
GROUP BY current_code_1