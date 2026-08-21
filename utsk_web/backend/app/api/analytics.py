from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db, verify_token
from ..config import logger
router = APIRouter()

@router.get('/api/analytics/monthly-revenue')
def monthly_revenue(token: str=Query(None), year: int=2026, db: Session=Depends(get_db)):
    """Динамика выручки по месяцам (товар + услуги)"""
    verify_token(token)
    try:
        result = db.execute(text('SELECT * FROM get_monthly_revenue(:year)'), {'year': year})
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in ['goods_revenue', 'services_revenue', 'total_revenue']:
                if key in r and r[key] is not None:
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        return {'status': 'ok', 'year': year, 'data': data, 'count': len(data)}
    except Exception as e:
        logger.error(f'Ошибка monthly_revenue: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/yoy-comparison')
def yoy_comparison(token: str=Query(None), year1: int=2026, year2: int=2025, db: Session=Depends(get_db)):
    """Сравнение двух годов (честный YoY — одни и те же клиенты в обоих годах)"""
    verify_token(token)
    try:
        result = db.execute(text('SELECT * FROM get_yoy_comparison(:year1, :year2)'), {'year1': year1, 'year2': year2})
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            if r.get('goods_revenue_y2', 0) > 0:
                r['growth_pct'] = round((r.get('goods_revenue_y1', 0) - r.get('goods_revenue_y2', 0)) / r['goods_revenue_y2'] * 100, 1)
            else:
                r['growth_pct'] = None
            data.append(r)
        return {'status': 'ok', 'year1': year1, 'year2': year2, 'data': data, 'count': len(data)}
    except Exception as e:
        logger.error(f'Ошибка yoy_comparison: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/pivot-report')
def pivot_report(token: str=Query(None), year: int=2026, multiplier: float=2.9, limit_price: float=146000, direction: str='below', db: Session=Depends(get_db)):
    """PIVOT-таблица ABC-сегментации из generate_custom_sales_report"""
    verify_token(token)
    try:
        result = db.execute(text('SELECT * FROM generate_custom_sales_report(:year, :multiplier, :limit_price, :direction)'), {'year': year, 'multiplier': multiplier, 'limit_price': limit_price, 'direction': direction})
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        return {'status': 'ok', 'params': {'year': year, 'multiplier': multiplier, 'limit_price': limit_price, 'direction': direction}, 'data': data, 'count': len(data)}
    except Exception as e:
        logger.error(f'Ошибка pivot_report: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/pivot-formatted')
def pivot_formatted(token: str=Query(None), year: int=2026, multiplier: float=2.9, limit_price: float=146000, db: Session=Depends(get_db)):
    """PIVOT-отчёт: группы C2 и ABC с правильными названиями метрик"""
    verify_token(token)
    try:
        below_result = db.execute(text("SELECT * FROM generate_custom_sales_report(:year, :multiplier, :limit_price, 'below')"), {'year': year, 'multiplier': multiplier, 'limit_price': limit_price})
        above_result = db.execute(text("SELECT * FROM generate_custom_sales_report(:year, :multiplier, :limit_price, 'above')"), {'year': year, 'multiplier': multiplier, 'limit_price': limit_price})

        def rows_to_list(result):
            data = []
            for row in result:
                r = dict(row._mapping)
                for key in r:
                    if r[key] is not None:
                        try:
                            r[key] = round(float(r[key]), 2)
                        except (ValueError, TypeError):
                            pass
                data.append(r)
            return data
        below_data = rows_to_list(below_result)
        above_data = rows_to_list(above_result)
        return {'status': 'ok', 'params': {'year': year, 'multiplier': multiplier, 'limit_price': limit_price}, 'below': below_data, 'above': above_data, 'below_count': len(below_data), 'above_count': len(above_data)}
    except Exception as e:
        logger.error(f'Ошибка pivot_formatted: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/abc-groups')
def abc_groups(token: str=Query(None), year: int=2026, multiplier: float=2.9, db: Session=Depends(get_db)):
    """ABC-сегментация: группы A1..C2 + Total (из get_abc_groups)"""
    verify_token(token)
    try:
        result = db.execute(text('SELECT * FROM get_abc_groups(:year, :multiplier)'), {'year': year, 'multiplier': multiplier})
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        return {'status': 'ok', 'params': {'year': year, 'multiplier': multiplier}, 'data': data, 'count': len(data)}
    except Exception as e:
        logger.error(f'Ошибка abc_groups: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/daily-revenue')
def daily_revenue(token: str=Query(None), year: int=2026, month: int=5, db: Session=Depends(get_db)):
    """Выручка по дням внутри месяца"""
    verify_token(token)
    try:
        result = db.execute(text('SELECT * FROM get_daily_revenue(:year, :month)'), {'year': year, 'month': month})
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        return {'status': 'ok', 'year': year, 'month': month, 'data': data, 'count': len(data)}
    except Exception as e:
        logger.error(f'Ошибка daily_revenue: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/monthly-detail')
def monthly_detail(token: str=Query(None), year: int=2026, month: int=5, db: Session=Depends(get_db)):
    """Метрики за текущий и прошлый месяц + структура товары/услуги"""
    verify_token(token)
    try:
        current = db.execute(text('SELECT * FROM get_monthly_detail_metrics(:year, :month)'), {'year': year, 'month': month}).first()
        prev_month = month - 1
        prev_year = year
        if prev_month == 0:
            prev_month = 12
            prev_year = year - 1
        previous = db.execute(text('SELECT * FROM get_monthly_detail_metrics(:year, :month)'), {'year': prev_year, 'month': prev_month}).first()

        def row_to_dict(row):
            if not row:
                return {}
            r = dict(row._mapping)
            for k in r:
                if r[k] is not None:
                    r[k] = round(float(r[k]), 2)
                else:
                    r[k] = 0.0
            return r
        current_dict = row_to_dict(current)
        previous_dict = row_to_dict(previous)
        growth = {}
        for key in ['goods_revenue', 'invoice_count', 'active_clients', 'services_revenue']:
            prev_val = previous_dict.get(key, 0) or 0
            curr_val = current_dict.get(key, 0) or 0
            growth[key] = round(float((curr_val - prev_val) / prev_val * 100), 1) if prev_val > 0 else None
        curr_inv = max(current_dict.get('invoice_count', 1), 1)
        prev_inv = max(previous_dict.get('invoice_count', 1), 1)
        current_dict['avg_ticket'] = round(float(current_dict.get('goods_revenue', 0)) / float(curr_inv), 2)
        previous_dict['avg_ticket'] = round(float(previous_dict.get('goods_revenue', 0)) / float(prev_inv), 2)
        prev_ticket = previous_dict.get('avg_ticket', 0) or 0
        curr_ticket = current_dict.get('avg_ticket', 0) or 0
        growth['avg_ticket'] = round(float((curr_ticket - prev_ticket) / prev_ticket * 100), 1) if prev_ticket > 0 else None
        return {'status': 'ok', 'current': {'year': year, 'month': month, **current_dict}, 'previous': {'year': prev_year, 'month': prev_month, **previous_dict}, 'growth': growth}
    except Exception as e:
        logger.error(f'Ошибка monthly_detail: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/abc-migration')
def abc_migration(token: str=Query(None), year: int=2026, groups: str='A1,A2,B1,B2', multiplier: float=2.9, db: Session=Depends(get_db)):
    """
    Клиенты с ABC-группой groups в year-1 → их метрики в year.
    groups: список через запятую (A1,A2,B1,B2 или C1,C2)
    """
    verify_token(token)
    try:
        year_prev = year - 1
        group_list = [g.strip() for g in groups.split(',')]
        result = db.execute(text('SELECT * FROM get_abc_migration(:year, :groups, :multiplier)'), {'year': year, 'groups': group_list, 'multiplier': multiplier})
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        return {'status': 'ok', 'year_prev': year_prev, 'year': year, 'groups': groups, 'data': data, 'count': len(data)}
    except Exception as e:
        logger.error(f'Ошибка abc_migration: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/zaletnye')
def zaletnye(token: str=Query(None), year: int=2026, multiplier: float=2.9, db: Session=Depends(get_db)):
    """Залётные: C1/C2 в прошлом году + новые клиенты → их метрики в текущем"""
    verify_token(token)
    try:
        year_prev = year - 1
        result = db.execute(text('SELECT * FROM get_zaletnye(:year, :multiplier)'), {'year': year, 'multiplier': multiplier})
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        return {'status': 'ok', 'year_prev': year_prev, 'year': year, 'data': data, 'count': len(data)}
    except Exception as e:
        logger.error(f'Ошибка zaletnye: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/monthly-directions')
def monthly_directions(token: str=Query(None), year: int=2026, month: int=5, db: Session=Depends(get_db)):
    """Выручка по направлениям за месяц"""
    verify_token(token)
    try:
        result = db.execute(text('SELECT * FROM get_monthly_directions(:year, :month)'), {'year': year, 'month': month})
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        return {'status': 'ok', 'year': year, 'month': month, 'data': data, 'count': len(data)}
    except Exception as e:
        logger.error(f'Ошибка monthly_directions: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/monthly-products')
def monthly_products(token: str=Query(None), year: int=2026, month: int=5, limit: int=10, db: Session=Depends(get_db)):
    """Топ товаров за месяц"""
    verify_token(token)
    try:
        result = db.execute(text('SELECT * FROM get_monthly_products(:year, :month, :limit)'), {'year': year, 'month': month, 'limit': limit})
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        return {'status': 'ok', 'year': year, 'month': month, 'data': data, 'count': len(data)}
    except Exception as e:
        logger.error(f'Ошибка monthly_products: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/monthly-top-clients')
def monthly_top_clients(token: str=Query(None), year: int=2026, month: int=5, limit: int=10, multiplier: float=2.9, db: Session=Depends(get_db)):
    """Топ-клиенты за месяц с ABC-группой из прошлого года"""
    verify_token(token)
    try:
        year_prev = year - 1
        result = db.execute(text('SELECT * FROM get_monthly_top_clients(:year, :month, :year_prev, :mult, :limit)'), {'year': year, 'month': month, 'year_prev': year_prev, 'mult': multiplier, 'limit': limit})
        data = []
        for i, row in enumerate(result):
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            r['position'] = i + 1
            data.append(r)
        return {'status': 'ok', 'year': year, 'month': month, 'data': data, 'count': len(data)}
    except Exception as e:
        logger.error(f'Ошибка monthly_top_clients: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/yearly-clients-count')
def yearly_clients_count(token: str=Query(None), year: int=2026, db: Session=Depends(get_db)):
    """Количество активных клиентов за год (из client_year_activity)"""
    verify_token(token)
    try:
        result = db.execute(text('SELECT get_yearly_clients_count(:year)'), {'year': year}).scalar()
        return {'status': 'ok', 'year': year, 'active_clients': result}
    except Exception as e:
        logger.error(f'Ошибка yearly_clients_count: {e}')
        raise HTTPException(status_code=500, detail=str(e))

def fetch_pivot_data_sync(db, year, multiplier, limit_price, direction):
    """Синхронная версия получения PIVOT-данных"""
    try:
        result = db.execute(text('SELECT * FROM generate_custom_sales_report(:year, :multiplier, :limit_price, :direction)'), {'year': year, 'multiplier': multiplier, 'limit_price': limit_price, 'direction': direction})
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        return data
    except Exception as e:
        logger.error(f'Ошибка fetch_pivot_data для {direction}: {e}')
        return []

def parse_pivot_data(below_data, above_data):
    """Парсит PIVOT-данные в формат с groups"""
    result = {'groups': [], 'pivot': {'below': below_data, 'above': above_data}}
    groups_dict = {}
    for row in above_data:
        group_name = row.get('out_group_name')
        metric = row.get('out_metric')
        if group_name and group_name not in ['Total', 'Итого']:
            if group_name not in groups_dict:
                groups_dict[group_name] = {'out_group_name': group_name, 'out_total_companies': 0, 'out_total_sales': 0, 'out_total_invoices': 0}
            if metric == 'Кол-во компаний':
                groups_dict[group_name]['out_total_companies'] = row.get('out_total', 0)
            elif metric == 'Сумма продаж':
                groups_dict[group_name]['out_total_sales'] = row.get('out_total', 0)
            elif metric == 'Накладных':
                groups_dict[group_name]['out_total_invoices'] = row.get('out_total', 0)
    result['groups'] = list(groups_dict.values())
    order = {'A1': 1, 'A2': 2, 'A3': 3, 'B1': 4, 'B2': 5, 'C1': 6, 'C2': 7}
    result['groups'].sort(key=lambda x: order.get(x.get('out_group_name', ''), 99))
    total_data = None
    for row in above_data:
        if row.get('out_group_name') == 'Total':
            if row.get('out_metric') == 'Кол-во компаний':
                if not total_data:
                    total_data = {'out_group_name': 'Total', 'out_total_companies': 0, 'out_total_sales': 0, 'out_total_invoices': 0}
                total_data['out_total_companies'] = row.get('out_total', 0)
            elif row.get('out_metric') == 'Сумма продаж':
                if not total_data:
                    total_data = {'out_group_name': 'Total', 'out_total_companies': 0, 'out_total_sales': 0, 'out_total_invoices': 0}
                total_data['out_total_sales'] = row.get('out_total', 0)
            elif row.get('out_metric') == 'Накладных':
                if not total_data:
                    total_data = {'out_group_name': 'Total', 'out_total_companies': 0, 'out_total_sales': 0, 'out_total_invoices': 0}
                total_data['out_total_invoices'] = row.get('out_total', 0)
    if total_data:
        result['groups'].append(total_data)
    return result

@router.get('/api/analytics/abc-comparison')
def abc_comparison(token: str=Query(None), year: int=2026, multiplier: float=2.9, limit_price: float=146000, db: Session=Depends(get_db)):
    """Сравнение ABC-сегментации за два года"""
    verify_token(token)
    try:
        prev_year = year - 1
        current_below = fetch_pivot_data_sync(db, year, multiplier, limit_price, 'below')
        current_above = fetch_pivot_data_sync(db, year, multiplier, limit_price, 'above')
        current_data = parse_pivot_data(current_below, current_above)
        prev_below = fetch_pivot_data_sync(prev_year, multiplier, limit_price, 'below')
        prev_above = fetch_pivot_data_sync(prev_year, multiplier, limit_price, 'above')
        prev_data = parse_pivot_data(prev_below, prev_above)
        return {'status': 'ok', 'current_year': year, 'prev_year': prev_year, 'current': current_data, 'prev': prev_data}
    except Exception as e:
        logger.error(f'Ошибка abc_comparison: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/recurrent-clients')
def recurrent_clients(token: str=Query(None), year: int=2026, multiplier: float=2.9, db: Session=Depends(get_db)):
    """Детальный список повторных клиентов (2-3 накладных за год) с ABC-группой"""
    verify_token(token)
    try:
        result = db.execute(text('SELECT * FROM get_recurrent_clients(:year, :multiplier)'), {'year': year, 'multiplier': multiplier})
        data = []
        for row in result:
            r = dict(row._mapping)
            days = r.get('days_between') or 0
            inv_count = int(r.get('invoice_count', 2))
            if days <= 7:
                rec_class = 'g1'
                rec_label = 'Ближе к разовым'
                recommendation = 'Стимулировать регулярность'
            elif inv_count >= 3:
                rec_class = 'g3'
                rec_label = 'Ближе к постоянным'
                recommendation = 'Программа лояльности'
            else:
                rec_class = 'g2'
                rec_label = 'Повторные (Центр)'
                recommendation = 'Рамочное соглашение'
            data.append({'client_code': r['client_code'], 'client_name': r['name'] or '', 'ipn': r['ipn'] or '', 'okpo': r['okpo_code'] or '', 'invoice_count': inv_count, 'goods_revenue': float(r['goods_revenue'] or 0), 'first_date': str(r['first_date']) if r['first_date'] else '', 'last_date': str(r['last_date']) if r['last_date'] else '', 'days_between': days, 'abc_group': r.get('abc_group', 'C2'), 'rec_class': rec_class, 'rec_label': rec_label, 'recommendation': recommendation})
        return {'status': 'ok', 'year': year, 'data': data, 'count': len(data)}
    except Exception as e:
        logger.error(f'Ошибка recurrent_clients: {e}')
        return {'status': 'error', 'detail': str(e)}

@router.get('/api/analytics/clients-yoy')
def clients_yoy(token: str=Query(None), year: int=2026, multiplier: float=2.9, db: Session=Depends(get_db)):
    """YoY-сравнение клиентов: ABC-группа текущего и прошлого года, выручка, изменение"""
    verify_token(token)
    try:
        year_prev = year - 1
        result = db.execute(text('SELECT * FROM get_clients_yoy(:year, :multiplier)'), {'year': year, 'multiplier': multiplier})
        data = []
        for row in result:
            r = dict(row._mapping)
            rev_c = float(r.get('revenue_curr') or 0)
            rev_p = float(r.get('revenue_prev') or 0)
            delta_pct = round((rev_c - rev_p) / rev_p * 100, 1) if rev_p > 0 else None
            data.append({'client_code': r['client_code'], 'client_name': r['client_name'] or '', 'revenue_curr': rev_c, 'revenue_prev': rev_p, 'invoices_curr': int(r.get('invoices_curr') or 0), 'invoices_prev': int(r.get('invoices_prev') or 0), 'abc_curr': r.get('abc_curr', 'Новый'), 'abc_prev': r.get('abc_prev', 'Новый'), 'delta_pct': delta_pct, 'is_new': rev_p == 0, 'is_lost': rev_c == 0})
        groups_order = ['A1', 'A2', 'A3', 'B1', 'B2', 'C1', 'C2']
        stats_curr = {}
        stats_prev = {}
        for d in data:
            g = d['abc_curr']
            if g in groups_order:
                if g not in stats_curr:
                    stats_curr[g] = {'group': g, 'count': 0, 'revenue': 0}
                stats_curr[g]['count'] += 1
                stats_curr[g]['revenue'] += d['revenue_curr']
            g2 = d['abc_prev']
            if g2 in groups_order:
                if g2 not in stats_prev:
                    stats_prev[g2] = {'group': g2, 'count': 0, 'revenue': 0}
                stats_prev[g2]['count'] += 1
                stats_prev[g2]['revenue'] += d['revenue_prev']
        max_month_curr = db.execute(text('SELECT COALESCE(MAX(EXTRACT(MONTH FROM invoice_date)), 12) FROM documents WHERE EXTRACT(YEAR FROM invoice_date) = :year'), {'year': year}).scalar()
        month_names = ['', 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь']
        return {'status': 'ok', 'year': year, 'year_prev': year_prev, 'max_month': int(max_month_curr), 'note': f'Сравнение за {int(max_month_curr)} мес. ({month_names[int(max_month_curr)]})', 'data': data, 'count': len(data), 'stats_curr': [stats_curr[g] for g in groups_order if g in stats_curr], 'stats_prev': [stats_prev[g] for g in groups_order if g in stats_prev]}
    except Exception as e:
        logger.error(f'Ошибка clients_yoy: {e}')
        return {'status': 'error', 'detail': str(e)}

@router.get('/api/analytics/segment-comparison')
def get_segment_comparison(token: str=Query(None), year_current: int=2026, year_previous: int=2025, db: Session=Depends(get_db)):
    """
    Полный набор данных для страницы сравнения сегментов.
    Возвращает 6 групп RFM + 4 альтернативные группы.
    Использует функции get_rfm_funnel и get_alt_funnel.
    """
    verify_token(token)
    try:
        rfm_data = {}
        alt_data = {}
        for year in [year_current, year_previous]:
            rows_rfm = db.execute(text('SELECT * FROM get_rfm_funnel(:year)'), {'year': year}).fetchall()
            groups_rfm = {'one': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0}, 'repeat': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0}, 'quarter': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0}, 'month': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0}, 'week': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0}, 'day': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0}}
            for row in rows_rfm:
                r = dict(row._mapping)
                g_key = r['rfm_group']
                if g_key in groups_rfm:
                    groups_rfm[g_key] = {'companies': int(r['companies'] or 0), 'invoices': int(r['invoices'] or 0), 'sales': float(r['sales'] or 0), 'avg_check': float(r['avg_check'] or 0)}
            total_companies_rfm = sum((g['companies'] for g in groups_rfm.values()))
            total_sales_rfm = sum((g['sales'] for g in groups_rfm.values()))
            rfm_data[str(year)] = {'groups': groups_rfm, 'total_companies': total_companies_rfm, 'total_invoices': sum((g['invoices'] for g in groups_rfm.values())), 'total_sales': total_sales_rfm, 'avg_check': round(total_sales_rfm / total_companies_rfm, 2) if total_companies_rfm else 0}
            rows_alt = db.execute(text('SELECT * FROM get_alt_funnel(:year, 2.9, 146000)'), {'year': year}).fetchall()
            groups_alt = {}
            tot_comp_alt = 0
            tot_sales_alt = 0.0
            for row in rows_alt:
                r = dict(row._mapping)
                k = r['group_key']
                comp = int(r['companies'] or 0)
                sales = float(r['sales'] or 0)
                avg_chk = float(r['avg_check'] or 0)
                groups_alt[k] = {'companies': comp, 'sales': sales, 'avg_check': avg_chk}
                tot_comp_alt += comp
                tot_sales_alt += sales
            alt_data[str(year)] = {'groups': groups_alt, 'total_companies': tot_comp_alt, 'total_sales': round(tot_sales_alt, 2)}
        return {'status': 'ok', 'rfm': rfm_data, 'alt': alt_data, 'years': {'current': year_current, 'previous': year_previous}}
    except Exception as e:
        logger.error(f'Ошибка в get_segment_comparison: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/abc-structure')
def abc_structure(token: str=Query(None), year: int=2026, multiplier: float=2.9, limit_price: float=146000, active_only: bool=True, db: Session=Depends(get_db)):
    """Возвращает структурированные данные для 4 секций ABC-анализа"""
    verify_token(token)
    try:
        report_rows = db.execute(text('SELECT * FROM get_abc_structure_data(:year, :multiplier, :limit_price)'), {'year': year, 'multiplier': multiplier, 'limit_price': limit_price}).fetchall()
        if not report_rows:
            return {'status': 'ok', 'data': {'sections': {}, 'year': year, 'active_count': 0}}
        below_rows = [r for r in report_rows if r._mapping.get('out_direction') == 'below']
        above_rows = [r for r in report_rows if r._mapping.get('out_direction') == 'above']

        def parse_data(result):
            """Парсит результат в структуру {группа: {метрика: {диапазон: значение}}}"""
            data = {}
            for row in result:
                r = dict(row._mapping)
                group = r.get('out_group_name')
                metric = r.get('out_metric')
                if group not in data:
                    data[group] = {}
                data[group][metric] = {'1': float(r.get('out_1', 0) or 0), '2_3': float(r.get('out_2_3', 0) or 0), '4_10': float(r.get('out_4_10', 0) or 0), '11_40': float(r.get('out_11_40', 0) or 0), '41_170': float(r.get('out_41_170', 0) or 0), '171_plus': float(r.get('out_171_plus', 0) or 0), 'total': float(r.get('out_total', 0) or 0)}
            return data
        below = parse_data(below_rows)
        above = parse_data(above_rows)

        def get_metric_dict(data_dict, default_grp, metric_name):
            if metric_name == 'Накладных':
                return data_dict.get('Всего', {}).get('Накладных', {}) or data_dict.get(default_grp, {}).get('Накладных', {})
            return data_dict.get(default_grp, {}).get(metric_name, {})
        metric_names = ['Кол-во компаний', 'Накладных', 'Сумма продаж', 'Средний чек', '% от общ']
        metric_keys = ['companies', 'invoices', 'sales', 'avg_ticket', 'pct']
        ranges = ['1', '2_3', '4_10', '11_40', '41_170', '171_plus']
        c2_sec = {}
        abc_sec = {}
        for i, metric in enumerate(metric_names):
            k = metric_keys[i]
            c2_sec[k] = get_metric_dict(below, 'C2', metric) or {'1': 0, '2_3': 0, '4_10': 0, '11_40': 0, '41_170': 0, '171_plus': 0, 'total': 0}
            abc_sec[k] = get_metric_dict(above, 'ABC', metric) or {'1': 0, '2_3': 0, '4_10': 0, '11_40': 0, '41_170': 0, '171_plus': 0, 'total': 0}
        grand_sales = c2_sec['sales'].get('total', 0) + abc_sec['sales'].get('total', 0) or 1.0
        c2_sec['pct'] = {r: round(c2_sec['sales'].get(r, 0) / grand_sales * 100, 2) for r in ranges}
        c2_sec['pct']['total'] = round(c2_sec['sales'].get('total', 0) / grand_sales * 100, 2)
        abc_sec['pct'] = {r: round(abc_sec['sales'].get(r, 0) / grand_sales * 100, 2) for r in ranges}
        abc_sec['pct']['total'] = round(abc_sec['sales'].get('total', 0) / grand_sales * 100, 2)
        total_sec = {'companies': {r: c2_sec['companies'].get(r, 0) + abc_sec['companies'].get(r, 0) for r in ranges}, 'invoices': {r: c2_sec['invoices'].get(r, 0) + abc_sec['invoices'].get(r, 0) for r in ranges}, 'sales': {r: c2_sec['sales'].get(r, 0) + abc_sec['sales'].get(r, 0) for r in ranges}}
        total_sec['companies']['total'] = sum((total_sec['companies'][r] for r in ranges))
        total_sec['invoices']['total'] = sum((total_sec['invoices'][r] for r in ranges))
        total_sec['sales']['total'] = sum((total_sec['sales'][r] for r in ranges))
        total_sec['avg_ticket'] = {r: round(total_sec['sales'][r] / total_sec['invoices'][r], 2) if total_sec['invoices'][r] else 0.0 for r in ranges}
        total_sec['avg_ticket']['total'] = round(total_sec['sales']['total'] / total_sec['invoices']['total'], 2) if total_sec['invoices']['total'] else 0.0
        total_sec['pct'] = {r: round(total_sec['sales'][r] / grand_sales * 100, 2) for r in ranges}
        total_sec['pct']['total'] = round(total_sec['sales']['total'] / grand_sales * 100, 2)
        c2_4plus_ranges = ['4_10', '11_40', '41_170', '171_plus']
        imp_sec = {'companies': {r: abc_sec['companies'].get(r, 0) + (c2_sec['companies'].get(r, 0) if r in c2_4plus_ranges else 0) for r in ranges}, 'invoices': {r: abc_sec['invoices'].get(r, 0) + (c2_sec['invoices'].get(r, 0) if r in c2_4plus_ranges else 0) for r in ranges}, 'sales': {r: abc_sec['sales'].get(r, 0) + (c2_sec['sales'].get(r, 0) if r in c2_4plus_ranges else 0) for r in ranges}}
        imp_sec['companies']['total'] = sum((imp_sec['companies'][r] for r in ranges))
        imp_sec['invoices']['total'] = sum((imp_sec['invoices'][r] for r in ranges))
        imp_sec['sales']['total'] = sum((imp_sec['sales'][r] for r in ranges))
        imp_sec['avg_ticket'] = {r: round(imp_sec['sales'][r] / imp_sec['invoices'][r], 2) if imp_sec['invoices'][r] else 0.0 for r in ranges}
        imp_sec['avg_ticket']['total'] = round(imp_sec['sales']['total'] / imp_sec['invoices']['total'], 2) if imp_sec['invoices']['total'] else 0.0
        imp_sec['pct'] = {r: round(imp_sec['sales'][r] / grand_sales * 100, 2) for r in ranges}
        imp_sec['pct']['total'] = round(imp_sec['sales']['total'] / grand_sales * 100, 2)
        c2_sec['name'] = 'Случайные C2'
        c2_sec['icon'] = '📥'
        abc_sec['name'] = 'Основные ABC'
        abc_sec['icon'] = '📈'
        total_sec['name'] = 'Все ABC'
        total_sec['icon'] = '📊'
        imp_sec['name'] = 'Важные — ABC'
        imp_sec['icon'] = '⭐'
        result = {'year': year, 'multiplier': multiplier, 'limit_price': limit_price, 'active_count': int(total_sec['companies']['total']), 'sections': {'c2': c2_sec, 'abc': abc_sec, 'total': total_sec, 'important': imp_sec}}
        return {'status': 'ok', 'data': result}
    except Exception as e:
        logger.error(f'Ошибка abc_structure: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/c2-detail')
def c2_detail(token: str=Query(None), year: int=2026, multiplier: float=2.9, limit_price: float=146000, active_only: bool=True, db: Session=Depends(get_db)):
    """Глубокий анализ сегмента C2 с распаковкой повторных и внутренней ABC-классификацией"""
    verify_token(token)
    try:
        sql = text('SELECT * FROM get_c2_detail(:year, :multiplier, :limit_price)')
        rows = db.execute(sql, {'year': year, 'multiplier': multiplier, 'limit_price': limit_price}).fetchall()
        rows_prev = db.execute(sql, {'year': year - 1, 'multiplier': multiplier, 'limit_price': limit_price}).fetchall()
        freq_groups = ['1', '2_1d', '2_diff', '3', '4_10', '11_40', '41_plus']
        classes = ['A', 'B', 'C']
        matrix = {cls: {fg: {'comp': 0, 'inv': 0, 'sales': 0.0} for fg in freq_groups} for cls in classes}
        matrix_prev = {cls: {fg: {'comp': 0, 'inv': 0, 'sales': 0.0} for fg in freq_groups} for cls in classes}
        local_abc = {cls: {'comp': 0, 'inv': 0, 'sales': 0.0} for cls in classes}
        repeat_decomp = {fg: {'comp': 0, 'inv': 0, 'sales': 0.0} for fg in freq_groups}
        total_comp = 0
        total_inv = 0
        total_sales = 0.0
        for r in rows:
            cls = r.internal_class
            fg = r.freq_group
            sales = float(r.goods_revenue or 0)
            inv = int(r.invoices_count or 0)
            total_comp += 1
            total_inv += inv
            total_sales += sales
            local_abc[cls]['comp'] += 1
            local_abc[cls]['inv'] += inv
            local_abc[cls]['sales'] += sales
            repeat_decomp[fg]['comp'] += 1
            repeat_decomp[fg]['inv'] += inv
            repeat_decomp[fg]['sales'] += sales
            matrix[cls][fg]['comp'] += 1
            matrix[cls][fg]['inv'] += inv
            matrix[cls][fg]['sales'] += sales
        for r in rows_prev:
            cls = r.internal_class
            fg = r.freq_group
            sales = float(r.goods_revenue or 0)
            inv = int(r.invoices_count or 0)
            matrix_prev[cls][fg]['comp'] += 1
            matrix_prev[cls][fg]['inv'] += inv
            matrix_prev[cls][fg]['sales'] += sales
        comp_2_1d = repeat_decomp['2_1d']['comp']
        comp_2_diff = repeat_decomp['2_diff']['comp']
        total_2_comp = comp_2_1d + comp_2_diff
        false_repeat_pct = round(comp_2_1d / total_2_comp * 100, 1) if total_2_comp > 0 else 0.0
        class_a_sales_pct = round(local_abc['A']['sales'] / total_sales * 100, 1) if total_sales > 0 else 0.0
        class_a_comp_pct = round(local_abc['A']['comp'] / total_comp * 100, 1) if total_comp > 0 else 0.0
        return {'status': 'ok', 'year': year, 'year_prev': year - 1, 'limit_price': limit_price, 'data': {'total_companies': total_comp, 'total_invoices': total_inv, 'total_sales': round(total_sales, 2), 'avg_ticket': round(total_sales / total_inv, 2) if total_inv else 0.0, 'local_abc': local_abc, 'repeat_decomp': repeat_decomp, 'matrix': matrix, 'matrix_prev': matrix_prev, 'kpis': {'false_repeat_pct': false_repeat_pct, 'class_a_sales_pct': class_a_sales_pct, 'class_a_comp_pct': class_a_comp_pct, 'false_repeat_comp': comp_2_1d, 'true_repeat_comp': comp_2_diff}}}
    except Exception as e:
        logger.error(f'Ошибка c2_detail: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/segment-detail')
def segment_detail(token: str=Query(None), segment: str=Query('abc'), year: int=2026, multiplier: float=2.9, limit_price: float=146000, active_only: bool=True, db: Session=Depends(get_db)):
    """Детальный анализ любого сегмента (c2, abc, total, important) с матрицей и локальным ABC"""
    verify_token(token)
    try:
        sql = text('SELECT * FROM get_segment_detail(:segment, :year, :multiplier, :limit_price)')
        rows = db.execute(sql, {'segment': segment, 'year': year, 'multiplier': multiplier, 'limit_price': limit_price}).fetchall()
        rows_prev = db.execute(sql, {'segment': segment, 'year': year - 1, 'multiplier': multiplier, 'limit_price': limit_price}).fetchall()
        freq_groups = ['1', '2_1d', '2_diff', '3', '4_10', '11_40', '41_170', '171_plus']
        classes = ['A', 'B', 'C']
        matrix = {cls: {fg: {'comp': 0, 'inv': 0, 'sales': 0.0} for fg in freq_groups} for cls in classes}
        matrix_prev = {cls: {fg: {'comp': 0, 'inv': 0, 'sales': 0.0} for fg in freq_groups} for cls in classes}
        local_abc = {cls: {'comp': 0, 'inv': 0, 'sales': 0.0} for cls in classes}
        repeat_decomp = {fg: {'comp': 0, 'inv': 0, 'sales': 0.0} for fg in freq_groups}
        total_comp = 0
        total_inv = 0
        total_sales = 0.0
        for r in rows:
            cls = r.internal_class
            fg = r.freq_group
            sales = float(r.goods_revenue or 0)
            inv = int(r.invoices_count or 0)
            total_comp += 1
            total_inv += inv
            total_sales += sales
            local_abc[cls]['comp'] += 1
            local_abc[cls]['inv'] += inv
            local_abc[cls]['sales'] += sales
            repeat_decomp[fg]['comp'] += 1
            repeat_decomp[fg]['inv'] += inv
            repeat_decomp[fg]['sales'] += sales
            matrix[cls][fg]['comp'] += 1
            matrix[cls][fg]['inv'] += inv
            matrix[cls][fg]['sales'] += sales
        for r in rows_prev:
            cls = r.internal_class
            fg = r.freq_group
            sales = float(r.goods_revenue or 0)
            inv = int(r.invoices_count or 0)
            matrix_prev[cls][fg]['comp'] += 1
            matrix_prev[cls][fg]['inv'] += inv
            matrix_prev[cls][fg]['sales'] += sales
        comp_2_1d = repeat_decomp['2_1d']['comp']
        comp_2_diff = repeat_decomp['2_diff']['comp']
        total_2_comp = comp_2_1d + comp_2_diff
        false_repeat_pct = round(comp_2_1d / total_2_comp * 100, 1) if total_2_comp > 0 else 0.0
        class_a_sales_pct = round(local_abc['A']['sales'] / total_sales * 100, 1) if total_sales > 0 else 0.0
        class_a_comp_pct = round(local_abc['A']['comp'] / total_comp * 100, 1) if total_comp > 0 else 0.0
        return {'status': 'ok', 'segment': segment, 'year': year, 'year_prev': year - 1, 'limit_price': limit_price, 'data': {'total_companies': total_comp, 'total_invoices': total_inv, 'total_sales': round(total_sales, 2), 'avg_ticket': round(total_sales / total_inv, 2) if total_inv else 0.0, 'local_abc': local_abc, 'repeat_decomp': repeat_decomp, 'matrix': matrix, 'matrix_prev': matrix_prev, 'kpis': {'false_repeat_pct': false_repeat_pct, 'class_a_sales_pct': class_a_sales_pct, 'class_a_comp_pct': class_a_comp_pct, 'false_repeat_comp': comp_2_1d, 'true_repeat_comp': comp_2_diff}}}
    except Exception as e:
        logger.error(f'Ошибка segment_detail: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/abc-groups-detail')
def abc_groups_detail(token: str=Query(None), year: int=2026, multiplier: float=2.9, limit_price: float=146000, db: Session=Depends(get_db)):
    """Детальный анализ ABC-сегмента по группам A1, A2, A3, B1, B2, C1"""
    verify_token(token)
    try:
        sql = text('SELECT * FROM get_abc_groups_detail(:year, :multiplier, :limit_price)')
        rows = db.execute(sql, {'year': year, 'multiplier': multiplier, 'limit_price': limit_price}).fetchall()
        group_names = {'A1': 'A1 (>8.7 млн ₴)', 'A2': 'A2 (5.8 - 8.7 млн ₴)', 'A3': 'A3 (4.35 - 5.8 млн ₴)', 'B1': 'B1 (2.9 - 4.35 млн ₴)', 'B2': 'B2 (1.45 - 2.9 млн ₴)', 'C1': 'C1 (435 тыс - 1.45 млн ₴)', 'C2_above': 'C2 выше границы'}
        total_sales = sum((float(r.sales or 0) for r in rows))
        total_comp = sum((int(r.companies or 0) for r in rows))
        total_inv = sum((int(r.invoices or 0) for r in rows))
        groups_data = {}
        for r in rows:
            grp = r.abc_group
            sales = float(r.sales or 0)
            comp = int(r.companies or 0)
            inv = int(r.invoices or 0)
            groups_data[grp] = {'name': group_names.get(grp, grp), 'companies': comp, 'invoices': inv, 'sales': round(sales, 2), 'avg_ticket': round(sales / inv, 2) if inv else 0.0, 'pct_of_abc': round(sales / total_sales * 100, 1) if total_sales else 0.0}
        a1_sales = groups_data.get('A1', {}).get('sales', 0.0)
        a1_share = round(a1_sales / total_sales * 100, 1) if total_sales else 0.0
        return {'status': 'ok', 'year': year, 'multiplier': multiplier, 'limit_price': limit_price, 'data': {'total_companies': total_comp, 'total_invoices': total_inv, 'total_sales': round(total_sales, 2), 'avg_ticket': round(total_sales / total_inv, 2) if total_inv else 0.0, 'groups': groups_data, 'kpis': {'top_group_share': a1_share, 'avg_sales_per_client': round(total_sales / total_comp, 2) if total_comp else 0.0}}}
    except Exception as e:
        logger.error(f'Ошибка abc_groups_detail: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/important-detail')
def important_detail(token: str=Query(None), year: int=2026, multiplier: float=2.9, limit_price: float=146000, db: Session=Depends(get_db)):
    """Детальный анализ Важных клиентов (ABC + C2 с 4+ накладными)"""
    verify_token(token)
    try:
        sql = text('SELECT * FROM get_important_detail(:year, :multiplier, :limit_price)')
        rows = db.execute(sql, {'year': year, 'multiplier': multiplier, 'limit_price': limit_price}).fetchall()
        grand_total = float(rows[0].grand_total) if rows else 1.0
        total_comp = len(rows)
        total_inv = sum((int(r.invoices_count or 0) for r in rows))
        total_sales = sum((float(r.goods_revenue or 0) for r in rows))
        top_clients = []
        for r in rows[:15]:
            sales = float(r.goods_revenue or 0)
            inv = int(r.invoices_count or 0)
            top_clients.append({'client_code': r.client_code, 'client_name': r.client_name, 'invoices_count': inv, 'goods_revenue': round(sales, 2), 'avg_ticket': round(sales / inv, 2) if inv else 0.0, 'category': r.category})
        vip_sales_share = round(total_sales / grand_total * 100, 1)
        return {'status': 'ok', 'year': year, 'limit_price': limit_price, 'data': {'total_companies': total_comp, 'total_invoices': total_inv, 'total_sales': round(total_sales, 2), 'avg_ticket': round(total_sales / total_inv, 2) if total_inv else 0.0, 'vip_sales_share': vip_sales_share, 'top_clients': top_clients}}
    except Exception as e:
        logger.error(f'Ошибка important_detail: {e}')
        raise HTTPException(status_code=500, detail=str(e))

@router.get('/api/analytics/top-clients')
def top_clients(token: str=Query(None), year: int=Query(None), month: int=Query(None), limit: int=50, exclude_client: str=Query('9653'), db: Session=Depends(get_db)):
    """
    Топ-клиенты за указанный или последний доступный месяц с исключением указанного клиента.
    Возвращает клиентов для расчёта 80% на фронтенде.
    """
    verify_token(token)
    try:
        target_year = year or 2026
        target_month = month or 7
        check_count = db.execute(text('\n            SELECT COUNT(*) FROM documents\n            WHERE EXTRACT(YEAR FROM invoice_date) = :year AND EXTRACT(MONTH FROM invoice_date) = :month\n        '), {'year': target_year, 'month': target_month}).scalar()
        if check_count == 0:
            latest = db.execute(text('\n                SELECT EXTRACT(YEAR FROM invoice_date)::integer AS yr, EXTRACT(MONTH FROM invoice_date)::integer AS mo\n                FROM documents\n                ORDER BY invoice_date DESC LIMIT 1\n            ')).fetchone()
            if latest:
                target_year = latest.yr
                target_month = latest.mo
        result = db.execute(text('SELECT * FROM get_top_clients_monthly(:year, :month, :limit, :exclude_client)'), {'year': target_year, 'month': target_month, 'exclude_client': exclude_client, 'limit': limit}).fetchall()
        data = []
        total_revenue = 0
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            total_revenue += r.get('goods_revenue', 0)
            data.append(r)
        excluded_info = None
        if exclude_client:
            excl_row = db.execute(text('SELECT * FROM get_excluded_client_info(:year, :month, :exclude_client)'), {'year': target_year, 'month': target_month, 'exclude_client': exclude_client}).fetchone()
            if excl_row:
                excluded_info = dict(excl_row._mapping)
                if excluded_info.get('goods_revenue'):
                    excluded_info['goods_revenue'] = round(float(excluded_info['goods_revenue']), 2)
        return {'status': 'ok', 'year': target_year, 'month': target_month, 'data': data, 'total_revenue': round(total_revenue, 2), 'excluded_client': exclude_client, 'excluded_client_info': excluded_info, 'count': len(data)}
    except Exception as e:
        logger.error(f'Ошибка top_clients: {e}')
        raise HTTPException(status_code=500, detail=str(e))