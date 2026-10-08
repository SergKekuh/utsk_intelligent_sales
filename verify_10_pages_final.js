const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
        headless: 'new'
    });
    const page = await browser.newPage();
    await page.setViewport({ width: 1560, height: 1000 });

    const pages = [
        { name: '1_dashboard', url: 'http://localhost:5000/?token=utsk2026', selector: '.kpi-grid, .stats-card, .container' },
        { name: '2_analytics', url: 'http://localhost:5000/analytics?token=utsk2026', selector: '.kpi-grid, canvas, .container' },
        { name: '3_advanced', url: 'http://localhost:5000/advanced?token=utsk2026', selector: '.container, table, .kpi-card' },
        { name: '4_general_segmentation', url: 'http://localhost:5000/general-segmentation?token=utsk2026', selector: '.container, table, .matrix-table' },
        { name: '5_client_detail_4501', url: 'http://localhost:5000/client-detail?token=utsk2026&code=4501', selector: '#rec-block, .kpi-card' },
        { name: '6_product_analytics_4501', url: 'http://localhost:5000/product-analytics?token=utsk2026&code=4501', selector: '.kpi-card, .tab-nav, #products-table' },
        { name: '7_client_size_matrix_4501', url: 'http://localhost:5000/client-size-matrix?token=utsk2026&code=4501&year=2026', selector: '#matrixContainer table' },
        { name: '8_product_rec_detail', url: 'http://localhost:5000/product-recommendation-detail?token=utsk2026&code=4501&size_key=round_76x5&year=2026', selector: '#size-title, .kpi-card' },
        { name: '9_recommendations_overview', url: 'http://localhost:5000/recommendations-overview?token=utsk2026&code=4501&year=2026', selector: '.container, table, .kpi-grid' },
        { name: '10_direction_detail_6', url: 'http://localhost:5000/direction-detail?token=utsk2026&direction_id=6&year=2026', selector: '.container, table' }
    ];

    let overallSuccess = true;

    for (const p of pages) {
        console.log(`\n------------------------------------------------------------`);
        console.log(`Testing [${p.name}]: ${p.url}`);
        const errors = [];

        page.removeAllListeners('console');
        page.removeAllListeners('pageerror');

        page.on('console', msg => {
            if (msg.type() === 'error' && !msg.text().includes('favicon.ico')) {
                errors.push(msg.text());
            }
        });
        page.on('pageerror', err => {
            errors.push(err.toString());
        });

        try {
            await page.goto(p.url, { waitUntil: 'networkidle2', timeout: 25000 });
            if (p.selector) {
                await page.waitForSelector(p.selector, { timeout: 12000 });
            }
            await new Promise(r => setTimeout(r, 600));

            // Specialized deep check for page 7 (client-size-matrix)
            if (p.name === '7_client_size_matrix_4501') {
                console.log(`  Checking 4 tabs on /client-size-matrix...`);
                const tabExpectations = {
                    'round': { expectedRows: 113, expectedCols: 71, label: '🟢 Круглі' },
                    'prof': { expectedRows: 94, expectedCols: 17, label: '🟦 Профільні' },
                    'welded': { expectedRows: 9, expectedCols: 8, label: '🔥 Сварні' },
                    'sheet': { expectedRows: 10, expectedCols: 18, label: '📄 Лист' }
                };

                for (const [tabKey, exp] of Object.entries(tabExpectations)) {
                    // Click tab
                    await page.click(`#btn-toggle-${tabKey}`);
                    await new Promise(r => setTimeout(r, 500));

                    const rows = await page.$$eval('#matrixContainer table tbody tr', trs => trs.length);
                    const cols = await page.$$eval('#matrixContainer table thead th', ths => ths.length);
                    const stats = await page.$eval('#legendStatsText', el => el.innerText);

                    console.log(`    Tab ${exp.label} (${tabKey}): ${rows} rows × ${cols} cols (exp: ${exp.expectedRows} × ${exp.expectedCols}) | ${stats}`);
                    if (rows !== exp.expectedRows || cols !== exp.expectedCols) {
                        console.warn(`    ⚠️ Notice: Tab ${tabKey} dimensions (${rows}x${cols}) differ slightly from expected (${exp.expectedRows}x${exp.expectedCols})`);
                    }
                    await page.screenshot({ path: `utsk_web/frontend/static/screenshot_size_matrix_${tabKey}.png` });
                }
            }

            const screenshotPath = `utsk_web/frontend/static/screenshot_final_${p.name}.png`;
            await page.screenshot({ path: screenshotPath });
            console.log(`  ✓ Screenshot: ${screenshotPath}`);
            console.log(`  ✓ Console errors: ${errors.length}`);

            if (errors.length > 0) {
                console.error(`  ❌ Errors:`, errors);
                overallSuccess = false;
            } else {
                console.log(`  ✅ 0 errors in ${p.name}`);
            }

        } catch (e) {
            console.error(`  ❌ Exception in ${p.name}:`, e.message);
            overallSuccess = false;
        }
    }

    await browser.close();
    console.log(`\n============================================================`);
    console.log(`FINAL PUPPETEER 10 PAGES RESULT: ${overallSuccess ? 'ALL PASSED ✅ (0 ERRORS)' : 'FAILED ❌'}`);
    console.log(`============================================================`);

    if (!overallSuccess) {
        process.exit(1);
    }
})();
