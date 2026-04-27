BEGIN;

DELETE FROM product_similarities;

WITH pipes AS (
    SELECT code, diameter, wall_thickness, is_profile
    FROM products WHERE diameter IS NOT NULL AND COALESCE(in_stock_balance, 0) > 0
)
INSERT INTO product_similarities (
    source_product_code, similar_product_code, similarity_score, match_type,
    source_diameter, source_wall, similar_diameter, similar_wall
)
SELECT 
    a.code, b.code,
    ROUND(100 - LEAST(ABS(a.diameter - b.diameter) * 1.5, 40) - LEAST(ABS(a.wall_thickness - b.wall_thickness) * 8, 40) - CASE WHEN a.is_profile != b.is_profile THEN 30 ELSE 0 END, 2) AS score,
    CASE 
        WHEN a.is_profile = b.is_profile AND ABS(a.diameter - b.diameter) < 2 AND ABS(a.wall_thickness - b.wall_thickness) > 0 THEN 'same_diameter'
        WHEN a.is_profile = b.is_profile AND ABS(a.diameter - b.diameter) > 0 AND ABS(a.wall_thickness - b.wall_thickness) < 0.5 THEN 'same_wall'
        WHEN a.is_profile = b.is_profile AND ABS(a.diameter - b.diameter) <= 20 THEN 'same_profile'
        WHEN b.diameter >= a.diameter AND b.wall_thickness >= a.wall_thickness THEN 'upgrade'
        WHEN b.diameter <= a.diameter AND b.wall_thickness <= a.wall_thickness THEN 'downgrade'
        ELSE 'similar'
    END,
    a.diameter, a.wall_thickness, b.diameter, b.wall_thickness
FROM pipes a CROSS JOIN pipes b
WHERE a.code != b.code AND ABS(a.diameter - b.diameter) <= 30 AND ABS(a.wall_thickness - b.wall_thickness) <= 4
  AND ROUND(100 - LEAST(ABS(a.diameter - b.diameter) * 1.5, 40) - LEAST(ABS(a.wall_thickness - b.wall_thickness) * 8, 40) - CASE WHEN a.is_profile != b.is_profile THEN 30 ELSE 0 END, 2) > 50
ON CONFLICT DO NOTHING;

COMMIT;
