import re

with open('utsk_web/frontend/static/analytics.html', 'r') as f:
    content = f.read()

# 1. Update loadGeneralSegmentation Promise.all
old_load = """                        var [respCurr, respPast] = await Promise.all([
                            fetch('/api/analytics/segmentation-current-year?token=' + TOKEN + '&year=' + year + '&limit_price=' + limitPrice),
                            fetch('/api/analytics/segmentation-past-years?token=' + TOKEN + '&year=' + year)
                        ]);

                        var jsonCurr = await respCurr.json();
                        var jsonPast = await respPast.json();

                        if (jsonCurr.status === 'ok' && jsonPast.status === 'ok') {
                            segMatrixData = jsonCurr;
                            segPastData = jsonPast;
                            renderSegTables(jsonCurr, jsonPast, year);"""

new_load = """                        var [respCurr, respPast, respRecurrent] = await Promise.all([
                            fetch('/api/analytics/segmentation-current-year?token=' + TOKEN + '&year=' + year + '&limit_price=' + limitPrice),
                            fetch('/api/analytics/segmentation-past-years?token=' + TOKEN + '&year=' + year),
                            fetch('/api/analytics/recurrent-clients?token=' + TOKEN + '&year=' + year)
                        ]);

                        var jsonCurr = await respCurr.json();
                        var jsonPast = await respPast.json();
                        var jsonRecurrent = await respRecurrent.json();

                        if (jsonCurr.status === 'ok' && jsonPast.status === 'ok') {
                            segMatrixData = jsonCurr;
                            segPastData = jsonPast;
                            renderSegTables(jsonCurr, jsonPast, year, jsonRecurrent);"""

content = content.replace(old_load, new_load)

# 2. Update renderSegTables signature and add povtBreakdown
old_render = """                function renderSegTables(currRes, pastRes, year) {
                    var currMap = (currRes && currRes.by_freq) || {};
                    var currTotals = (currRes && currRes.totals) || {};
                    var sleepMap = (pastRes && pastRes.sleeping_by_freq) || {};
                    var churnMap = (pastRes && pastRes.churned_by_freq) || {};"""

new_render = """                function renderSegTables(currRes, pastRes, year, recurrentRes) {
                    var currMap = (currRes && currRes.by_freq) || {};
                    var currTotals = (currRes && currRes.totals) || {};
                    var sleepMap = (pastRes && pastRes.sleeping_by_freq) || {};
                    var churnMap = (pastRes && pastRes.churned_by_freq) || {};

                    // === Разбивка повторных (2-3) по подгруппам ===
                    var recurrentRows = (recurrentRes && (recurrentRes.data || recurrentRes.rows)) || [];
                    var povtBreakdown = { dubl: 0, center: 0, cand: 0 };
                    recurrentRows.forEach(function(r) {
                        var lbl = String(r.rec_label || '');
                        if (lbl.indexOf('разовым') !== -1)       povtBreakdown.dubl++;
                        else if (lbl.indexOf('Центр') !== -1)    povtBreakdown.center++;
                        else if (lbl.indexOf('постоянным') !== -1) povtBreakdown.cand++;
                    });"""

content = content.replace(old_render, new_render)

# 3. Update Table 1 Dec & Cons
old_t1 = """                    // 3. Повторні (розкладені): — | 25 | 87 | 62 | — | — | — | 174
                    setVal('t1-dec-dubl', 25);
                    setVal('t1-dec-center', 87);
                    setVal('t1-dec-cand', 62);
                    setVal('t1-dec-all', 174);

                    // 5. Всі (консолідовано): (226+25)=251 | 87 | 62 | 188 | 126 | 13 | 2 | 729
                    var elConsRaz = document.getElementById('t1-cons-raz');
                    if (elConsRaz) {
                        elConsRaz.innerHTML = '(226+25)<br><span class="text-xs text-amber-600">= 251</span>';
                        elConsRaz.title = '226 разових + 25 дублів = 251';
                    }
                    setVal('t1-cons-center', 87);
                    setVal('t1-cons-cand', 62);
                    setVal('t1-cons-kvart', 188);
                    setVal('t1-cons-mes', 126);
                    setVal('t1-cons-ned', genNed);
                    setVal('t1-cons-den', 2);
                    setVal('t1-cons-all', 729);"""

new_t1 = """                    // 3. Повторні (розкладені) — из /api/analytics/recurrent-clients
                    setVal('t1-dec-dubl',   povtBreakdown.dubl);
                    setVal('t1-dec-center', povtBreakdown.center);
                    setVal('t1-dec-cand',   povtBreakdown.cand);
                    setVal('t1-dec-all',    povtBreakdown.dubl + povtBreakdown.center + povtBreakdown.cand);

                    // 5. Всі (консолідовано)
                    var genRaz   = (currMap.raz && Number(currMap.raz.total_count)) || 0;
                    var consRaz  = genRaz + povtBreakdown.dubl;

                    var elConsRaz = document.getElementById('t1-cons-raz');
                    if (elConsRaz) {
                        elConsRaz.innerHTML = '(' + genRaz + '+' + povtBreakdown.dubl + ')<br>'
                            + '<span class="text-xs text-amber-600">= ' + consRaz + '</span>';
                        elConsRaz.title = genRaz + ' разових + ' + povtBreakdown.dubl + ' дублів = ' + consRaz;
                    }

                    setVal('t1-cons-center', povtBreakdown.center);
                    setVal('t1-cons-cand',   povtBreakdown.cand);

                    var consKvart = (currMap.kvart && Number(currMap.kvart.total_count)) || 0;
                    var consMes   = (currMap.mes   && Number(currMap.mes.total_count))   || 0;
                    var consDen   = (currMap.den   && Number(currMap.den.total_count))   || 0;

                    setVal('t1-cons-kvart', consKvart);
                    setVal('t1-cons-mes',   consMes);
                    setVal('t1-cons-ned',   genNed);
                    setVal('t1-cons-den',   consDen);

                    var consAll = consRaz + povtBreakdown.center + povtBreakdown.cand
                                + consKvart + consMes + genNed + consDen;
                    setVal('t1-cons-all', consAll);"""

content = content.replace(old_t1, new_t1)

with open('utsk_web/frontend/static/analytics.html', 'w') as f:
    f.write(content)

print("Patch 4B2 applied successfully.")
