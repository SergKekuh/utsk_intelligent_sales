import re

with open('utsk_web/frontend/static/analytics.html', 'r') as f:
    content = f.read()

old_block = """                    // ====== ТАБЛИЦЯ 3 ======
                    // 1. Вибули (Ушедшие) (из БД): 96 | 48 | 30 | 16 | 3 | 1 | 0 | 194
                    setVal('t3-churn-raz', 96);
                    setVal('t3-churn-povt', 48);
                    setVal('t3-churn-cand', 30);
                    setVal('t3-churn-kvart', 16);
                    setVal('t3-churn-mes', 3);
                    setVal('t3-churn-ned', 1);
                    setVal('t3-churn-den', 0);
                    setVal('t3-churn-all', 194);

                    // 2. Сплячі (из БД): 42 | 26 | 12 | 6 | 2 | 0 | 0 | 88
                    setVal('t3-sleep-raz', 42);
                    setVal('t3-sleep-povt', 26);
                    setVal('t3-sleep-cand', 12);
                    setVal('t3-sleep-kvart', 6);
                    setVal('t3-sleep-mes', 2);
                    setVal('t3-sleep-ned', 0);
                    setVal('t3-sleep-den', 0);
                    setVal('t3-sleep-all', 88);"""

new_block = """                    // ====== ТАБЛИЦЯ 3: ВИБУЛИ / СПЛЯЧІ ======
                    // Источник: API get_segmentation_past_years → pastRes.churned_by_freq / pastRes.sleeping_by_freq
                    // Поле: <map>[группа].total_count
                    // Фикс 2026-09-29: убран хардкод (96|48|30|16|3|1|0|194 и 42|26|12|6|2|0|0).

                    function getCount(map, group) {
                        return (map && map[group] && Number(map[group].total_count)) || 0;
                    }

                    // --- Вибули (churn) ---
                    setVal('t3-churn-raz',   getCount(churnMap, 'raz'));
                    setVal('t3-churn-povt',  getCount(churnMap, 'povt'));
                    setVal('t3-churn-cand',  0); // кандидаты в API не выделены — оставляем 0
                    setVal('t3-churn-kvart', getCount(churnMap, 'kvart'));
                    setVal('t3-churn-mes',   getCount(churnMap, 'mes'));
                    setVal('t3-churn-ned',   getCount(churnMap, 'ned'));
                    setVal('t3-churn-den',   getCount(churnMap, 'den'));

                    var churnTotal = ['raz', 'povt', 'kvart', 'mes', 'ned', 'den']
                        .reduce(function(sum, k) { return sum + getCount(churnMap, k); }, 0);
                    setVal('t3-churn-all', churnTotal);

                    // --- Сплячі (sleep) ---
                    setVal('t3-sleep-raz',   getCount(sleepMap, 'raz'));
                    setVal('t3-sleep-povt',  getCount(sleepMap, 'povt'));
                    setVal('t3-sleep-cand',  0);
                    setVal('t3-sleep-kvart', getCount(sleepMap, 'kvart'));
                    setVal('t3-sleep-mes',   getCount(sleepMap, 'mes'));
                    setVal('t3-sleep-ned',   getCount(sleepMap, 'ned'));
                    setVal('t3-sleep-den',   getCount(sleepMap, 'den'));

                    var sleepTotal = ['raz', 'povt', 'kvart', 'mes', 'ned', 'den']
                        .reduce(function(sum, k) { return sum + getCount(sleepMap, k); }, 0);
                    setVal('t3-sleep-all', sleepTotal);"""

if old_block in content:
    content = content.replace(old_block, new_block)
    with open('utsk_web/frontend/static/analytics.html', 'w') as f:
        f.write(content)
    print("Patch 4B1 applied successfully.")
else:
    print("Old block not found!")
