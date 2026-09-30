import re

with open('utsk_web/frontend/static/analytics.html', 'r') as f:
    content = f.read()

old_block = """                    // ====== ТАБЛИЦЯ 2 ======
                    // 1. Лайт: 30 | 60 | 0 | 126 | 121 | 13 | 2 | 352
                    setVal('t2-c2-raz', 30);
                    setVal('t2-c2-povt', 60);
                    setVal('t2-c2-cand', 0);
                    setVal('t2-c2-kvart', 126);
                    setVal('t2-c2-mes', 121);
                    setVal('t2-c2-ned', 13);
                    setVal('t2-c2-den', 2);
                    setVal('t2-c2-all', 352);"""

new_block = """                    // ====== ТАБЛИЦЯ 2: ЛАЙТ (C2) ======
                    // Источник: API get_segmentation_current_year → currRes.by_freq
                    // Поле: currMap[группа].c2_count
                    // Раньше здесь был захардкоженный мок: 30|60|0|126|121|13|2|352
                    // Фикс 2026-09-29: заменили на реальные данные из БД.

                    function getC2Count(group) {
                        return (currMap && currMap[group] && Number(currMap[group].c2_count)) || 0;
                    }

                    setVal('t2-c2-raz',   getC2Count('raz'));
                    setVal('t2-c2-povt',  getC2Count('povt'));
                    setVal('t2-c2-cand',  0); // кандидаты (3 покупки) в c2_count не выделены — оставляем 0
                    setVal('t2-c2-kvart', getC2Count('kvart'));
                    setVal('t2-c2-mes',   getC2Count('mes'));
                    setVal('t2-c2-ned',   getC2Count('ned'));
                    setVal('t2-c2-den',   getC2Count('den'));

                    // Итого Лайт = сумма всех корзин (без кандидатов, чтобы не задвоить)
                    var c2Total = ['raz', 'povt', 'kvart', 'mes', 'ned', 'den']
                        .reduce(function(sum, k) { return sum + getC2Count(k); }, 0);
                    setVal('t2-c2-all', c2Total);"""

if old_block in content:
    content = content.replace(old_block, new_block)
    with open('utsk_web/frontend/static/analytics.html', 'w') as f:
        f.write(content)
    print("Patch applied successfully.")
else:
    print("Old block not found!")
