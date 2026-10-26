#!/usr/bin/env python3
"""
Парсер PDF ТУ У В.2.7-24.2-24238290-004:2015
Извлекает Таблицу А.1 (квадраты) и А.2 (прямоугольники).
"""
import pdfplumber
import csv
import re
from pathlib import Path

PDF_PATH = "date/tu_prof.pdf"
OUT_SQUARES = "date/squares.csv"
OUT_RECTANGLES = "date/rectangles.csv"


def is_number(val):
    """Проверить, является ли значение числом."""
    if val is None:
        return False
    try:
        float(str(val).replace(',', '.').replace(' ', ''))
        return True
    except (ValueError, TypeError):
        return False


def to_float(val):
    """Преобразовать в float."""
    if val is None:
        return None
    try:
        return float(str(val).replace(',', '.').replace(' ', '').strip())
    except (ValueError, TypeError):
        return None


def extract_squares(pdf):
    """
    Извлечь Таблицу А.1 — квадратные трубы (стр. 22–31).
    
    Колонки: h=b, t, A, Ix=Iy, Wx=Wy, Wp(nn)x, ix=iy, Ik, Wk, As, l1m, M
    """
    squares = []
    current_h = None
    
    # Страницы А.1 — 22-31 (1-indexed → 21-30 в Python)
    for page_num in range(21, 31):
        page = pdf.pages[page_num]
        tables = page.extract_tables()
        
        for table in tables:
            for row in table:
                if not row or len(row) < 3:
                    continue
                
                # Отсечь None в конце
                row = [c for c in row if c is not None or True]  # сохранить позиции
                while row and row[-1] is None:
                    row.pop()
                
                # Проверка: первая ячейка — число (h) или None
                h = to_float(row[0]) if len(row) > 0 else None
                t = to_float(row[1]) if len(row) > 1 else None
                
                if h is not None and h > 0:
                    current_h = h
                elif current_h is None:
                    continue
                
                # Пропустить строки без t (заголовки)
                if t is None or t <= 0 or t > 20:
                    continue
                
                squares.append({
                    "h": int(current_h),
                    "t": t,
                    "area_cm2": to_float(row[2]) if len(row) > 2 else None,
                    "ix_cm4": to_float(row[3]) if len(row) > 3 else None,
                    "wx_cm3": to_float(row[4]) if len(row) > 4 else None,
                    "wpl_x_cm3": to_float(row[5]) if len(row) > 5 else None,
                    "ik_cm4": to_float(row[7]) if len(row) > 7 else None,
                    "wk_cm3": to_float(row[8]) if len(row) > 8 else None,
                    "weight_m": to_float(row[11]) if len(row) > 11 else None,
                })
    
    # Дедупликация
    seen = {}
    for r in squares:
        key = (r["h"], r["t"])
        if key not in seen:
            seen[key] = r
    return list(seen.values())


def extract_rectangles(pdf):
    """
    Извлечь Таблицу А.2 — прямоугольные трубы (стр. 32–58).
    
    Колонки: h, b, t, A, Ix, Iy, Wx, Wy, Wp(nn)x, Wp(nn)y, ix, iy, Ik, Wk, As, l1m, M
    """
    rectangles = []
    current_h = None
    current_b = None
    
    # Страницы А.2 — 32-58 (1-indexed → 31-57 в Python)
    for page_num in range(31, 58):
        page = pdf.pages[page_num]
        tables = page.extract_tables()
        
        for table in tables:
            for row in table:
                if not row or len(row) < 3:
                    continue
                
                # Отсечь None в конце
                while row and row[-1] is None:
                    row.pop()
                
                h = to_float(row[0]) if len(row) > 0 else None
                b = to_float(row[1]) if len(row) > 1 else None
                t = to_float(row[2]) if len(row) > 2 else None
                
                # Forward-fill h и b
                if h is not None and h > 0:
                    current_h = h
                if b is not None and b > 0:
                    current_b = b
                
                if current_h is None or current_b is None:
                    continue
                
                if t is None or t <= 0 or t > 20:
                    continue
                
                rectangles.append({
                    "h": int(current_h),
                    "b": int(current_b),
                    "t": t,
                    "area_cm2": to_float(row[3]) if len(row) > 3 else None,
                    "ix_cm4": to_float(row[4]) if len(row) > 4 else None,
                    "iy_cm4": to_float(row[5]) if len(row) > 5 else None,
                    "wx_cm3": to_float(row[6]) if len(row) > 6 else None,
                    "wy_cm3": to_float(row[7]) if len(row) > 7 else None,
                    "wpl_x_cm3": to_float(row[8]) if len(row) > 8 else None,
                    "wpl_y_cm3": to_float(row[9]) if len(row) > 9 else None,
                    "ik_cm4": to_float(row[12]) if len(row) > 12 else None,
                    "wk_cm3": to_float(row[13]) if len(row) > 13 else None,
                    "weight_m": to_float(row[16]) if len(row) > 16 else None,
                })
    
    # Дедупликация
    seen = {}
    for r in rectangles:
        key = (r["h"], r["b"], r["t"])
        if key not in seen:
            seen[key] = r
    return list(seen.values())


def save_csv(data, path, fieldnames):
    """Сохранить в CSV."""
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(data)


def main():
    with pdfplumber.open(PDF_PATH) as pdf:
        squares = extract_squares(pdf)
        rectangles = extract_rectangles(pdf)
    
    print(f"Квадратов: {len(squares)} (ожидается 251)")
    print(f"Прямоугольников: {len(rectangles)} (ожидается 838)")
    
    # Сохранить
    save_csv(
        squares, OUT_SQUARES,
        ["h", "t", "area_cm2", "ix_cm4", "wx_cm3", "wpl_x_cm3", "ik_cm4", "wk_cm3", "weight_m"]
    )
    save_csv(
        rectangles, OUT_RECTANGLES,
        ["h", "b", "t", "area_cm2", "ix_cm4", "iy_cm4", "wx_cm3", "wy_cm3",
         "wpl_x_cm3", "wpl_y_cm3", "ik_cm4", "wk_cm3", "weight_m"]
    )
    
    # Проверка контрольных точек
    print()
    print("─── Контрольные точки ───")
    for s in squares:
        if s["h"] == 200 and s["t"] == 8.0:
            print(f"200×200×8: area={s['area_cm2']}, ix={s['ix_cm4']}, wx={s['wx_cm3']}")
            print(f"  Ожидается: area=59.2, ix=3566.3, wx=356.6")
    
    for r in rectangles:
        if r["h"] == 100 and r["b"] == 50 and r["t"] == 4.0:
            print(f"100×50×4: area={r['area_cm2']}, ix={r['ix_cm4']}, iy={r['iy_cm4']}, wx={r['wx_cm3']}, wy={r['wy_cm3']}")
            print(f"  Ожидается: area=11.7, ix=152.6, iy=68.7, wx=30.5, wy=22.9")


if __name__ == "__main__":
    main()
