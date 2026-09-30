# Исключения и глобальные фильтры аналитики

## 🚫 Реестр клиентов-исключений

В проекте выделены клиенты, операции по которым не должны учитываться в рыночной коммерческой аналитике продаж:

| Код клиента | Название компании | ЄДРПОУ | ІПН | Причина исключения | Текущий статус в БД |
|:---:|:---|:---:|:---:|:---|:---:|
| `11230` | **НЬЮЕРДЖІ ТОВ** | `35431024` | `354310226507` | Материнская/служебная компания | is_active_current=False |
| `8814` | **Форпост-М ООО С-1** | `33453617` | `334536104846` | Материнская/служебная компания | is_active_current=False |
| `9653` | **Південтрансбудкомплект ТОВ** | `24238290` | `242382904636` | Материнская/служебная компания | is_active_current=False |

### Подробное описание причин исключения:
1. **Код `9653` — ООО «Південтрансбудкомплект» (Материнская компания):**
   - Является собственным юридическим лицом компании-холдинга. Внутрихолдинговые перемещения и технические накладные создают искусственный оборот свыше 125 млн ₴ в 2026 году.
2. **Код `11230` — ООО «НЬЮЕРДЖІ» (Служебный контрагент):**
   - Служебное юрлицо для технических расчетов и взаимозачетов.
3. **Код `8814` — ООО «Форпост-М» (Форпост-М ООО С-1):**
   - Согласно решению руководства от сентября 2026 года подлежит полному исключению из всех аналитических отчетов и модулей (включая модуль направлений).


## 📋 Перечень всех 48 SQL-функций с фильтрами клиентов

| Функция | Фильтрует 9653 | Фильтрует 11230 | Фильтрует 8814 (⚠️ Требуется добавить) |
|:---|:---:|:---:|:---:|
| `generate_custom_sales_report` | ✅ | ❌ | ❌ НЕТ |
| `get_abc_groups_detail` | ✅ | ❌ | ❌ НЕТ |
| `get_active_clients` | ✅ | ✅ | ❌ НЕТ |
| `get_alt_funnel` | ✅ | ✅ | ❌ НЕТ |
| `get_c2_detail` | ✅ | ❌ | ❌ НЕТ |
| `get_c2_segmentation_companies` | ✅ | ✅ | ❌ НЕТ |
| `get_c2_top_products` | ✅ | ✅ | ❌ НЕТ |
| `get_churned_segmentation` | ✅ | ✅ | ❌ НЕТ |
| `get_client_revenue_analytics` | ✅ | ✅ | ❌ НЕТ |
| `get_client_revenue_deep_analytics` | ✅ | ✅ | ❌ НЕТ |
| `get_consolidated_segmentation_companies` | ✅ | ✅ | ❌ НЕТ |
| `get_funnel_data` | ✅ | ✅ | ❌ НЕТ |
| `get_general_segmentation_companies` | ✅ | ✅ | ❌ НЕТ |
| `get_important_detail` | ✅ | ❌ | ❌ НЕТ |
| `get_inactive_clients_abc` | ✅ | ✅ | ❌ НЕТ |
| `get_inactive_clients_distribution` | ✅ | ✅ | ❌ НЕТ |
| `get_inactive_clients_list` | ✅ | ✅ | ❌ НЕТ |
| `get_inactive_clients_overview` | ✅ | ✅ | ❌ НЕТ |
| `get_new_clients_abc` | ✅ | ✅ | ❌ НЕТ |
| `get_new_clients_abc_compare` | ✅ | ✅ | ❌ НЕТ |
| `get_new_clients_frequency` | ✅ | ✅ | ❌ НЕТ |
| `get_new_clients_list` | ✅ | ✅ | ❌ НЕТ |
| `get_new_clients_monthly_revenue` | ✅ | ✅ | ❌ НЕТ |
| `get_new_clients_overview` | ✅ | ✅ | ❌ НЕТ |
| `get_new_clients_segmentation` | ✅ | ✅ | ❌ НЕТ |
| `get_product_categories` | ✅ | ✅ | ❌ НЕТ |
| `get_repeat_segmentation_companies` | ✅ | ✅ | ❌ НЕТ |
| `get_returned_clients_abc` | ✅ | ✅ | ❌ НЕТ |
| `get_returned_clients_frequency` | ✅ | ✅ | ❌ НЕТ |
| `get_returned_clients_list` | ✅ | ✅ | ❌ НЕТ |
| `get_returned_clients_overview` | ✅ | ✅ | ❌ НЕТ |
| `get_rfm_funnel` | ✅ | ✅ | ❌ НЕТ |
| `get_segment_detail` | ✅ | ✅ | ❌ НЕТ |
| `get_segment_detail` | ✅ | ❌ | ❌ НЕТ |
| `get_segmentation_current_year` | ✅ | ✅ | ❌ НЕТ |
| `get_segmentation_kpi` | ✅ | ✅ | ❌ НЕТ |
| `get_segmentation_matrix` | ✅ | ✅ | ❌ НЕТ |
| `get_segmentation_matrix_v2` | ✅ | ✅ | ❌ НЕТ |
| `get_segmentation_past_years` | ✅ | ✅ | ❌ НЕТ |
| `get_segmentation_special` | ✅ | ✅ | ❌ НЕТ |
| `get_sleeping_segmentation` | ✅ | ✅ | ❌ НЕТ |
| `get_top_clients_80pct` | ✅ | ✅ | ❌ НЕТ |
| `get_top_clients_monthly` | ✅ | ❌ | ❌ НЕТ |
| `get_top_companies` | ✅ | ✅ | ❌ НЕТ |
| `get_top_company_detail` | ✅ | ✅ | ❌ НЕТ |
| `get_top_compare_yoy` | ✅ | ✅ | ❌ НЕТ |
| `get_top_revenue_core` | ✅ | ✅ | ❌ НЕТ |
| `get_top_sales_kpi` | ✅ | ✅ | ❌ НЕТ |

---

## 🔍 Стандартные правила и предикаты фильтрации

В аналитических процедурах и представлениях применяются следующие стандартные условия:
1. **Только товарная выручка (исключение услуг):**
   ```sql
   COALESCE(pr.is_service, FALSE) = FALSE
   ```
2. **Только активные клиенты текущего года:**
   ```sql
   c.is_active_current = TRUE
   -- или проверка активности в конкретном расчетном году:
   EXISTS (
       SELECT 1 FROM client_year_activity cya 
       WHERE cya.client_code = c.code 
         AND cya.sales_year = p_year 
         AND cya.is_active = TRUE
   )
   ```
3. **Исключение внутрихолдинговых и технических операций:**
   ```sql
   c.code NOT IN ('9653', '11230', '8814')
   ```
4. **Фильтрация накладных по году:**
   ```sql
   EXTRACT(YEAR FROM d.invoice_date) = p_year
   ```

