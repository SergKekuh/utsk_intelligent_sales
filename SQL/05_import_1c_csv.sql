BEGIN;

CREATE TEMP TABLE tmp_1c_products (
    code VARCHAR(50), name VARCHAR(255),
    in_stock_balance VARCHAR(50), created_at VARCHAR(20), is_weight VARCHAR(10)
);

\copy tmp_1c_products FROM 'nomenclature_from_1c.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'WIN1251');

UPDATE products p
SET in_stock_balance = tmp.in_stock_balance::NUMERIC
FROM tmp_1c_products tmp
WHERE p.code = tmp.code;

INSERT INTO products (code, name, in_stock_balance, created_at, is_new_arrival)
SELECT tmp.code, LEFT(tmp.name, 255), tmp.in_stock_balance::NUMERIC,
       TO_DATE(tmp.created_at, 'YYYY-MM-DD'), TRUE
FROM tmp_1c_products tmp
WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.code = tmp.code);

UPDATE products p
SET 
    diameter = sub.diameter, wall_thickness = sub.wall,
    profile_width = sub.prof_w, profile_height = sub.prof_h,
    is_profile = sub.is_prof, standard_name = sub.standard,
    weight_per_meter = COALESCE(p.weight_per_meter, sub.weight_m)
FROM (
    SELECT p2.code, dims.diameter, dims.wall, dims.prof_w, dims.prof_h,
           dims.is_prof, dims.standard, dims.weight_m
    FROM products p2
    CROSS JOIN LATERAL parse_pipe_attributes(p2.name) dims
    WHERE dims.diameter IS NOT NULL
) sub
WHERE p.code = sub.code AND p.diameter IS NULL;

COMMIT;
