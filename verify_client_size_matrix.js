const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
        headless: 'new'
    });
    const page = await browser.newPage();
    await page.setViewport({ width: 1560, height: 1100 });

    const errors = [];
    page.on('console', msg => {
        if (msg.type() === 'error' && !msg.text().includes('favicon.ico')) {
            errors.push(msg.text());
        }
    });
    page.on('pageerror', err => errors.push(err.toString()));

    try {
        console.log('1. Testing /product-analytics?token=utsk2026&code=4501...');
        await page.goto('http://localhost:5000/product-analytics?token=utsk2026&code=4501', { waitUntil: 'networkidle2', timeout: 15000 });
        await page.waitForSelector('#btn-diversity-matrix', { timeout: 5000 });
        const btnText = await page.$eval('#btn-diversity-matrix', el => el.innerText.trim());
        const btnHref = await page.$eval('#btn-diversity-matrix', el => el.getAttribute('href'));
        console.log(`   ✓ Button found! Text: "${btnText}", Href: "${btnHref}"`);
        await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_product_analytics_button.png' });

        console.log('2. Testing /client-size-matrix?token=utsk2026&code=4501&year=2026...');
        await page.goto('http://localhost:5000/client-size-matrix?token=utsk2026&code=4501&year=2026', { waitUntil: 'networkidle2', timeout: 20000 });
        await page.waitForSelector('.size-matrix', { timeout: 10000 });

        const kpiPositions = await page.$eval('#kpiCatalogPositions', el => el.innerText.trim());
        const kpiSizes = await page.$eval('#kpiCatalogSizes', el => el.innerText.trim());
        const kpiBought = await page.$eval('#kpiClientBought', el => el.innerText.trim());
        const kpiRev = await page.$eval('#kpiClientRevenue', el => el.innerText.trim());
        console.log(`   ✓ KPI Cards loaded: Positions: ${kpiPositions}, Sizes: ${kpiSizes}, Bought: ${kpiBought}, Rev: ${kpiRev}`);

        const roundRows = await page.$$eval('.size-matrix tbody tr', trs => trs.length);
        console.log(`   ✓ Round matrix rendered rows: ${roundRows}`);
        await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_client_size_matrix_round.png' });

        console.log('3. Switching to profile pipes...');
        await page.click('#btn-toggle-prof');
        await new Promise(r => setTimeout(r, 600));
        const profRows = await page.$$eval('.size-matrix tbody tr', trs => trs.length);
        console.log(`   ✓ Profile matrix rendered rows: ${profRows}`);
        await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_client_size_matrix_prof.png' });

        console.log('4. Clicking a cell to open drilldown modal...');
        const boughtCell = await page.$('.cell-bought');
        if (boughtCell) {
            await boughtCell.click();
            await page.waitForSelector('#drillModal', { visible: true, timeout: 5000 });
            await page.waitForSelector('.drill-table', { timeout: 8000 });
            const modalTitle = await page.$eval('#modalTitle', el => el.innerText.trim());
            const itemsCount = await page.$$eval('.drill-table tbody tr', trs => trs.length);
            console.log(`   ✓ Drilldown modal opened: "${modalTitle}", products: ${itemsCount}`);
            await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_client_size_matrix_modal.png' });
        } else {
            console.warn('   ⚠️ No .cell-bought found to click');
        }

        console.log(`Total console/page errors: ${errors.length}`);
        if (errors.length > 0) {
            console.error('Errors:', errors);
        } else {
            console.log('✅ ALL TESTS PASSED WITH 0 ERRORS!');
        }

    } catch (e) {
        console.error('Test failed:', e);
        process.exit(1);
    } finally {
        await browser.close();
    }
})();
