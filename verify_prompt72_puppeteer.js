const puppeteer = require('puppeteer');
const path = require('path');

(async () => {
    const browser = await puppeteer.launch({
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
        headless: 'new'
    });
    const page = await browser.newPage();
    await page.setViewport({ width: 1480, height: 1100 });

    const errors = [];
    page.on('console', msg => {
        if (msg.type() === 'error' && !msg.text().includes('favicon.ico')) {
            errors.push(`[Console Error] ${msg.text()}`);
        }
    });
    page.on('pageerror', err => errors.push(`[Page Error] ${err.toString()}`));

    try {
        console.log('1. Checking Dashboard link on /?token=utsk2026...');
        await page.goto('http://localhost:5000/?token=utsk2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });
        const abcLinkExists = await page.$eval('a[href="/abc-analysis?token=utsk2026"]', el => el.innerText.trim());
        console.log('   ✓ Dashboard link found:', abcLinkExists);

        console.log('2. Opening /abc-analysis?token=utsk2026...');
        await page.goto('http://localhost:5000/abc-analysis?token=utsk2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });

        await page.waitForFunction(() => {
            const tbody = document.getElementById('table-abc-body');
            return tbody && tbody.children.length >= 8;
        }, { timeout: 10000 });

        const kpi2026 = await page.$eval('#kpi-rev-2026', el => el.innerText.trim());
        const clients2026 = await page.$eval('#kpi-clients-2026', el => el.innerText.trim());
        const tableText = await page.$eval('#main-abc-table', el => el.innerText);
        console.log('   ✓ KPI 2026:', kpi2026, '| Clients 2026:', clients2026);

        // Screenshot Tab 1 (Summary)
        const screenshotSummary = '/home/serg/Documents/SQL_postgresql/Intelligent_Sales/utsk_web/frontend/static/screenshot_abc_analysis_summary.png';
        await page.screenshot({ path: screenshotSummary, fullPage: true });
        console.log('   ✓ Saved screenshot:', screenshotSummary);

        // Test Tab 2 (Charts)
        console.log('3. Switching to Tab 2 (Charts)...');
        await page.evaluate(() => switchTab('tab-charts'));
        await new Promise(r => setTimeout(r, 600));
        const screenshotCharts = '/home/serg/Documents/SQL_postgresql/Intelligent_Sales/utsk_web/frontend/static/screenshot_abc_analysis_charts.png';
        await page.screenshot({ path: screenshotCharts, fullPage: true });
        console.log('   ✓ Saved screenshot:', screenshotCharts);

        // Test Tab 3 (Industries placeholder)
        console.log('4. Switching to Tab 3 (Industries)...');
        await page.evaluate(() => switchTab('tab-industries'));
        await new Promise(r => setTimeout(r, 300));
        const indText = await page.$eval('#table-industry-body', el => el.innerText.trim());
        console.log('   ✓ Industries table text:', indText);
        if (!indText.includes('Данные в разработке')) {
            throw new Error('Expected placeholder "Данные в разработке" in industries table');
        }

        // Test Tab 4 (Thresholds)
        console.log('5. Switching to Tab 4 (Thresholds)...');
        await page.evaluate(() => switchTab('tab-thresholds'));
        await new Promise(r => setTimeout(r, 300));
        const thrRowsCount = await page.$$eval('#table-thresholds-body tr', rows => rows.length);
        console.log('   ✓ Thresholds rows count:', thrRowsCount);
        if (thrRowsCount !== 21) {
            throw new Error(`Expected 21 rows in thresholds table, got ${thrRowsCount}`);
        }

        // Switch back to Summary and test period switches (6m, 12m, 9m) and priceMode (comp, both, fact)
        console.log('6. Testing period & price mode switches...');
        await page.evaluate(() => switchTab('tab-summary'));
        await page.click('#btn-period-12m');
        await new Promise(r => setTimeout(r, 500));
        const kpi2025_12m = await page.$eval('#kpi-rev-2025', el => el.innerText.trim());
        console.log('   ✓ 2025 12m KPI:', kpi2025_12m);

        await page.click('#btn-price-both');
        await new Promise(r => setTimeout(r, 300));
        await page.click('#btn-period-9m');
        await new Promise(r => setTimeout(r, 500));
        await page.click('#btn-price-fact');
        await new Promise(r => setTimeout(r, 300));

        if (errors.length > 0) {
            console.error('Errors detected:', errors);
            process.exit(1);
        }

        console.log('ALL PUPPETEER CHECKS PASSED (0 console errors)!');
    } catch (err) {
        console.error('Puppeteer verification failed:', err);
        process.exit(1);
    } finally {
        await browser.close();
    }
})();
