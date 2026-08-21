-- Migration 10: Fix get_active_clients, get_dashboard_stats, and get_churn_risk_clients to use MAX(invoice_date) instead of CURRENT_DATE
-- This prevents active clients and dashboard metrics from expiring as real-world date advances beyond historical dataset date (2026-06-30).

CREATE OR REPLACE FUNCTION public.get_active_clients(p_limit integer DEFAULT 20)
 RETURNS TABLE(code character varying, name character varying, status character varying, last_purchase_date date, docs_count bigint, total_revenue numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_max_date DATE;
BEGIN
    SELECT COALESCE(MAX(invoice_date), CURRENT_DATE) INTO v_max_date FROM documents;

    RETURN QUERY
    SELECT c.code, c.name, sr.status_name as status, c.last_purchase_date,
           COUNT(d.id)::BIGINT as docs_count, 
           COALESCE(SUM(d.total_amount), 0)::NUMERIC as total_revenue
    FROM clients c
    JOIN documents d ON d.client_code = c.code
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE d.invoice_date >= v_max_date - INTERVAL '90 days'
      AND c.code != ALL(ARRAY['9653', '11230'])
    GROUP BY c.code, c.name, sr.status_name, c.last_purchase_date
    ORDER BY total_revenue DESC 
    LIMIT p_limit;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_dashboard_stats()
 RETURNS TABLE(total_clients bigint, active_30d bigint, active_90d bigint, total_revenue numeric, revenue_30d numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_max_date DATE;
BEGIN
    SELECT COALESCE(MAX(invoice_date), CURRENT_DATE) INTO v_max_date FROM documents;

    RETURN QUERY
    SELECT 
        COUNT(DISTINCT c.code)::BIGINT as total_clients,
        COUNT(DISTINCT CASE WHEN c.last_purchase_date >= v_max_date - INTERVAL '30 days' THEN c.code END)::BIGINT as active_30d,
        COUNT(DISTINCT CASE WHEN c.last_purchase_date >= v_max_date - INTERVAL '90 days' THEN c.code END)::BIGINT as active_90d,
        COALESCE(SUM(d.total_amount), 0)::NUMERIC as total_revenue,
        COALESCE(SUM(CASE WHEN d.invoice_date >= v_max_date - INTERVAL '30 days' THEN d.total_amount END), 0)::NUMERIC as revenue_30d
    FROM clients c 
    LEFT JOIN documents d ON d.client_code = c.code;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_churn_risk_clients(p_limit integer DEFAULT 20)
 RETURNS TABLE(code character varying, name character varying, status character varying, last_purchase_date date, days_since_last integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_max_date DATE;
BEGIN
    SELECT COALESCE(MAX(invoice_date), CURRENT_DATE) INTO v_max_date FROM documents;

    RETURN QUERY
    SELECT c.code, c.name, sr.status_name as status, c.last_purchase_date,
           (v_max_date - c.last_purchase_date::DATE)::INT as days_since_last
    FROM clients c 
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE c.last_purchase_date IS NOT NULL
      AND c.last_purchase_date < v_max_date - INTERVAL '90 days'
    ORDER BY days_since_last DESC 
    LIMIT p_limit;
END;
$function$;
