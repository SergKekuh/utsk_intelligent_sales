const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
        headless: 'new'
    });
    const page = await browser.newPage();
    await page.setViewport({ width: 1440, height: 1000 });

    const pagesToTest = [
        {
            name: '1_dashboard',
            url: 'http://localhost:5000/?token=utsk2026',
            waitSelector: '.kpi-grid, .stats-card, .container',
            screenshot: 'utsk_web/frontend/static/screenshot_reg_1_dashboard.png'
        },
        {
            name: '2_analytics',
            url: 'http://localhost:5000/analytics?token=utsk2026',
            waitSelector: '.kpi-grid, .container, canvas',
            screenshot: 'utsk_web/frontend/static/screenshot_reg_2_analytics.png'
        },
        {
            name: '3_client_detail',
            url: 'http://localhost:5000/client-detail?token=utsk2026&code=4501&year=2026',
            waitSelector: '#rec-block',
            screenshot: 'utsk_web/frontend/static/screenshot_reg_3_client_detail.png'
        },
        {
            name: '4_product_rec_detail',
            url: 'http://localhost:5000/product-recommendation-detail?token=utsk2026&code=4501&size_key=round_76x5&year=2026',
            waitSelector: '#size-title',
            screenshot: 'utsk_web/frontend/static/screenshot_reg_4_product_rec_detail.png'
        },
        {
            name: '5_direction_detail',
            url: 'http://localhost:5000/direction-detail?token=utsk2026&direction_id=6&year=2026',
            waitSelector: '.container, table',
            screenshot: 'utsk_web/frontend/static/screenshot_reg_5_direction_detail.png'
        }
    ];

    let allPassed = true;

    for (const p of pagesToTest) {
        console.log(`Testing ${p.name}: ${p.url}...`);
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
            await page.goto(p.url, { waitUntil: 'networkidle2', timeout: 15000 });
            if (p.waitSelector) {
                await page.waitForSelector(p.waitSelector, { timeout: 10000 });
            }
            // Small extra delay for charts and dynamic elements
            await new Promise(r => setTimeout(r, 600));
            await page.screenshot({ path: p.screenshot });
            console.log(`  ✓ Screenshot saved: ${p.screenshot}`);
            console.log(`  ✓ Errors count: ${errors.length}`);
            if (errors.length > 0) {
                console.error(`  ❌ Errors in ${p.name}:`, errors);
                allPassed = false;
            } else {
                console.log(`  ✅ 0 errors in ${p.name}`);
            }
        } catch (e) {
            console.error(`  ❌ Exception in ${p.name}:`, e.message);
            allPassed = false;
        }
    }

    await browser.close();
    console.log(`Puppeteer 5 pages result: ${allPassed ? 'ALL PASSED ✅' : 'FAILED ❌'}`);
})();
