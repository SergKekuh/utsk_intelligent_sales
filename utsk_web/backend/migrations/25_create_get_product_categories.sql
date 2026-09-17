-- Migration 25: Create get_product_categories function for product classification analytics
CREATE OR REPLACE FUNCTION public.get_product_categories(p_year integer DEFAULT 2026)
RETURNS TABLE (
    id integer,
    name varchar,
    icon varchar,
    color varchar,
    revenue numeric,
    ton numeric,
    price_per_ton numeric,
    lines_count bigint
) 
LANGUAGE sql
STABLE
AS $$
    WITH cat_def AS (
        SELECT 1 AS id, 'Труба квадратная'::varchar AS name, '⬛'::varchar AS icon, '#3b82f6'::varchar AS color
        UNION ALL SELECT 2, 'Труба прямоугольная', '▬', '#8b5cf6'
        UNION ALL SELECT 3, 'Труба бесшовная горячедеформированная', '🔥', '#f59e0b'
        UNION ALL SELECT 4, 'Труба бесшовная холоднодеформированная', '❄️', '#06b6d4'
        UNION ALL SELECT 5, 'Труба электросварная', '⚡', '#10b981'
        UNION ALL SELECT 6, 'Листовой прокат', '📄', '#ef4444'
        UNION ALL SELECT 7, 'Услуги', '🛠️', '#64748b'
        UNION ALL SELECT 8, 'Прочее', '❓', '#94a3b8'
    ),
    raw_sales AS (
        SELECT
            CASE 
                -- 1. ТРУБА КВАДРАТНАЯ (равные стороны)
                WHEN p.name ~ '(\d+)\s*[хx]\s*\1' AND p.name ILIKE '%проф%' THEN 'Труба квадратная'
                
                -- 2. ТРУБА ПРЯМОУГОЛЬНАЯ (разные стороны)
                WHEN p.name ILIKE '%проф%' AND p.name !~ '(\d+)\s*[хx]\s*\1' THEN 'Труба прямоугольная'
                
                -- 3. ТРУБА БЕСШОВНАЯ ГОРЯЧЕДЕФОРМИРОВАННАЯ
                WHEN p.name ILIKE '%8732%' 
                     OR p.name ILIKE '%горячедеформ%' 
                     OR p.name ILIKE '%г/д%' THEN 'Труба бесшовная горячедеформированная'
                
                -- 4. ТРУБА БЕСШОВНАЯ ХОЛОДНОДЕФОРМИРОВАННАЯ
                WHEN p.name ILIKE '%8734%' 
                     OR p.name ILIKE '%8939%' 
                     OR p.name ILIKE '%холоднодеформ%' 
                     OR p.name ILIKE '%холоднотянут%' 
                     OR p.name ILIKE '%х/д%' THEN 'Труба бесшовная холоднодеформированная'
                
                -- 5. ТРУБА ЭЛЕКТРОСВАРНАЯ
                WHEN p.name ILIKE '%електрозвар%' 
                     OR p.name ILIKE '%электросвар%' 
                     OR p.name ILIKE '%10704%' 
                     OR p.name ILIKE '%10705%' 
                     OR p.name ILIKE '%8938%' THEN 'Труба электросварная'
                
                -- 6. ЛИСТОВОЙ ПРОКАТ
                WHEN p.name ILIKE '%лист%' 
                     OR p.name ILIKE '%19903%' THEN 'Листовой прокат'
                
                -- 7. УСЛУГИ
                WHEN p.is_service = TRUE 
                     OR p.name ILIKE '%поріз%' 
                     OR p.name ILIKE '%порез%' 
                     OR p.name ILIKE '%послуг%' 
                     OR p.name ILIKE '%дкпп%' THEN 'Услуги'
                
                ELSE 'Прочее'
            END AS category_name,
            sl.amount,
            sl.quantity * COALESCE(
                p.weight_per_meter,
                CASE 
                    WHEN p.profile_width > 0 AND p.profile_height > 0 AND p.wall_thickness > 0 
                    THEN 2 * (p.profile_width + p.profile_height) * p.wall_thickness * 0.00785 
                    ELSE 0.0 
                END
            ) / 1000.0 AS weight_ton
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products p ON sl.product_code = p.code
        WHERE d.client_code NOT IN ('9653', '11230')
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND sl.amount > 0
    ),
    agg_sales AS (
        SELECT 
            raw_sales.category_name,
            COUNT(*)::bigint AS lines_cnt,
            SUM(raw_sales.amount) AS rev,
            SUM(raw_sales.weight_ton) AS t
        FROM raw_sales
        GROUP BY raw_sales.category_name
    )
    SELECT
        cd.id,
        cd.name,
        cd.icon,
        cd.color,
        COALESCE(ROUND(ags.rev::numeric, 2), 0.00)::numeric AS revenue,
        COALESCE(ROUND(ags.t::numeric, 2), 0.00)::numeric AS ton,
        CASE 
            WHEN COALESCE(ags.t, 0) > 0 THEN ROUND((ags.rev / ags.t)::numeric, 2)
            ELSE 0.00
        END::numeric AS price_per_ton,
        COALESCE(ags.lines_cnt, 0)::bigint AS lines_count
    FROM cat_def cd
    LEFT JOIN agg_sales ags ON cd.name = ags.category_name
    ORDER BY cd.id;
$$;
