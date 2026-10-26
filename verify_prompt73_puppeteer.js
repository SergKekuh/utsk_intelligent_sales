const puppeteer = require('puppeteer');
const fs = require('fs');

const SHOTS = '/home/serg/Documents/SQL_postgresql/Intelligent_Sales/reports/screenshots';
const RU_WORDS = /(Выручка|Клиент(ов|ы)\b|Потребител|Отраслев|Срез\b|Обновить|Экспорт|Сохранить|Отмена|Нет данных|Данные в разработке|Период|Справочник|Сводный|Динамика|Калибр|ИТОГО|Сопоставим|Средний чек|контрагентов\b.*[ыэ])/;

(async () => {
    fs.mkdirSync(SHOTS, { recursive: true });
    const browser = await puppeteer.launch({ args: ['--no-sandbox', '--disable-setuid-sandbox'], headless: 'new' });
    const page = await browser.newPage();
    await page.setViewport({ width: 1480, height: 1100 });
    const errors = [];
    page.on('console', m => { if (m.type() === 'error' && !m.text().includes('favicon')) errors.push(m.text()); });
    page.on('pageerror', e => errors.push(String(e)));
    let ok = true;
    const check = (name, cond, info = '') => { console.log(`${cond ? '✓' : '✗'} ${name} ${info}`); if (!cond) ok = false; };

    await page.goto('http://localhost:5000/?token=utsk2026', { waitUntil: 'networkidle2' });
    const link = await page.$eval('a[href="/abc-analysis?token=utsk2026"]', el => el.innerText.trim());
    check('Sidebar link UA', link.includes('ABC-аналіз клієнтів'), link);

    await page.goto('http://localhost:5000/abc-analysis?token=utsk2026', { waitUntil: 'networkidle2' });
    await page.waitForFunction(() => document.getElementById('table-abc-body').children.length >= 8, { timeout: 10000 });
    await page.screenshot({ path: `${SHOTS}/abc_ua_summary.png`, fullPage: true });

    await page.evaluate(() => switchTab('tab-charts'));
    await new Promise(r => setTimeout(r, 700));
    await page.screenshot({ path: `${SHOTS}/abc_ua_charts.png`, fullPage: true });

    await page.evaluate(() => switchTab('tab-industries'));
    await new Promise(r => setTimeout(r, 900));
    await page.screenshot({ path: `${SHOTS}/abc_ua_industries.png`, fullPage: true });

    const ind = await page.evaluate(() => {
        const rows = [...document.querySelectorAll('#table-industry-body tr')];
        const total = rows.find(r => r.classList.contains('row-total'));
        return {
            rows: rows.length,
            totalText: total ? total.innerText : null,
            gridDisplay: getComputedStyle(document.getElementById('industry-charts-grid')).display,
            bar: !!Chart.getChart('chart-industry-bar'),
            donut: !!Chart.getChart('chart-industry-donut')
        };
    });
    console.log(JSON.stringify(ind));
    check('Industry rows (14 + total)', ind.rows === 15, String(ind.rows));
    check('Bar chart rendered', ind.bar);
    check('Donut chart rendered', ind.donut);
    const digits = (ind.totalText || '').replace(/[^\d\t]/g, '');
    check('Total 427 686 630 ₴ / 729', digits.includes('427686630') && digits.includes('729'), ind.totalText);

    // Switch periods and make sure nothing breaks
    for (const p of ['6m', '12m', '9m']) {
        await page.evaluate(pp => setPeriod(pp), p);
        await new Promise(r => setTimeout(r, 1200));
    }
    await page.evaluate(() => openThresholdModal());
    await page.evaluate(() => switchTab('tab-thresholds'));
    await new Promise(r => setTimeout(r, 400));
    await page.screenshot({ path: `${SHOTS}/abc_ua_thresholds.png`, fullPage: true });

    const text = await page.evaluate(() => document.body.innerText);
    const hit = text.match(RU_WORDS);
    check('No Russian UI words', !hit, hit ? hit[0] : '');
    check('0 console errors', errors.length === 0, errors.join(' | '));

    await browser.close();
    console.log(ok ? 'ALL PASS' : 'FAILED');
    process.exit(ok ? 0 : 1);
})();
