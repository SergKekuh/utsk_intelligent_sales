-- ====================================================================
-- MIGRATION 09: Clean Up Unused Functions and Views in Database
-- Database: bd_intelligent_sales
-- Date: 2026-08-13
-- ====================================================================

-- --------------------------------------------------------------------
-- STEP 1: BACKUP BEFORE DELETION
-- --------------------------------------------------------------------

-- Backup all functions
DROP TABLE IF EXISTS backup_functions_20260813;
CREATE TABLE backup_functions_20260813 AS
SELECT p.proname, pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
WHERE p.pronamespace = 'public'::regnamespace;

-- Backup all views
DROP TABLE IF EXISTS backup_views_20260813;
CREATE TABLE backup_views_20260813 AS
SELECT table_name, view_definition
FROM information_schema.views
WHERE table_schema = 'public';

-- --------------------------------------------------------------------
-- STEP 2: DROP 7 UNUSED FUNCTIONS
-- --------------------------------------------------------------------

DROP FUNCTION IF EXISTS public.calculate_client_direction CASCADE;
DROP FUNCTION IF EXISTS public.generate_custom_sales_report_no_filter CASCADE;
DROP FUNCTION IF EXISTS public.get_abc_segmentation_v2 CASCADE;
DROP FUNCTION IF EXISTS public.get_client_products_recommendations CASCADE;
DROP FUNCTION IF EXISTS public.get_companies_by_funnel_stage CASCADE;
DROP FUNCTION IF EXISTS public.reward_added_product CASCADE;
DROP FUNCTION IF EXISTS public.update_client_analytics CASCADE;

-- --------------------------------------------------------------------
-- STEP 3: DROP 10 UNUSED VIEWS
-- --------------------------------------------------------------------

DROP VIEW IF EXISTS public.v_abc_segmentation CASCADE;
DROP VIEW IF EXISTS public.v_annual_activity_report CASCADE;
DROP VIEW IF EXISTS public.v_churn_risk_dashboard CASCADE;
DROP VIEW IF EXISTS public.v_combined_annual_activity CASCADE;
DROP VIEW IF EXISTS public.v_direction_profitability CASCADE;
DROP VIEW IF EXISTS public.view_average_ticket_analytics CASCADE;
DROP VIEW IF EXISTS public.view_cohort_2026_integrity_check CASCADE;
DROP VIEW IF EXISTS public.v_abc_clients_detail CASCADE;
DROP VIEW IF EXISTS public.v_status_migration_matrix CASCADE;
DROP VIEW IF EXISTS public.v_clients_analytics_status CASCADE;
