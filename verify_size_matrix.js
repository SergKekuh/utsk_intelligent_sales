const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

(async () => {
    const browser = await puppeteer.launch({
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
        headless: 'new'
    });
    const page = await browser.newPage();
    await page.setViewport({ width: 1440, height: 1100 });

    const errors = [];
    page.on('console', msg => {
        if (msg.type() === 'error' && !msg.text().includes('favicon.ico')) {
            errors.push(`[Console Error] ${msg.text()}`);
        }
    });
    page.on('pageerror', err => errors.push(`[Page Error] ${err.toString()}`));

    let passedTests = 0;
    const totalTests = 7;

    try {
        console.log('=== TEST 1: General Size Matrix (/size-matrix without code) ===');
        await page.goto('http://localhost:5000/size-matrix?token=utsk2026&year=2026&from=dashboard', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });

        await page.waitForFunction(() => {
            const el = document.getElementById('kpiCatalogPositions');
            return el && el.textContent.trim() !== '—';
        }, { timeout: 10000 });

        const titleText = await page.$eval('#pageTitle', el => el.textContent.trim());
        const subTitleText = await page.$eval('#pageSubtitle', el => el.textContent.trim());
        const btnBackText = await page.$eval('#btnBackText', el => el.textContent.trim());
        const totalPositions = await page.$eval('#kpiCatalogPositions', el => el.textContent.trim());
        const totalSizes = await page.$eval('#kpiCatalogSizes', el => el.textContent.trim());

        console.log(`   ✓ Title: "${titleText}", Subtitle: "${subTitleText}"`);
        console.log(`   ✓ Back button text: "${btnBackText}"`);
        console.log(`   ✓ KPI Positions: "${totalPositions}", Sizes: "${totalSizes}"`);

        if (titleText !== 'Матриця розмірів' || !subTitleText.includes('4 450') || !btnBackText.includes('дашборд')) {
            throw new Error(`General matrix header mismatch: title=${titleText}, back=${btnBackText}`);
        }

        // Verify client-only KPI cards are hidden
        const clientCardDisplay = await page.$eval('.kpi-bought', el => window.getComputedStyle(el).display);
        if (clientCardDisplay !== 'none') {
            throw new Error(`kpi-bought should be hidden in general mode, got display=${clientCardDisplay}`);
        }
        console.log(`   ✓ Client-only cards properly hidden (display: none)`);
        passedTests++; // Test 1

        console.log('=== TEST 2: Client Mode (/size-matrix with code=4501) ===');
        await page.goto('http://localhost:5000/size-matrix?token=utsk2026&code=4501&year=2026&from=client', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });

        await page.waitForFunction(() => {
            const el = document.getElementById('kpiClientRevenue');
            return el && el.textContent.trim() !== '—';
        }, { timeout: 10000 });

        const clientTitle = await page.$eval('#pageTitle', el => el.textContent.trim());
        const clientSubtitle = await page.$eval('#pageSubtitle', el => el.textContent.trim());
        const clientBackText = await page.$eval('#btnBackText', el => el.textContent.trim());
        const clientRev = await page.$eval('#kpiClientRevenue', el => el.textContent.trim());
        const clientQty = await page.$eval('#kpiClientQty', el => el.textContent.trim());

        console.log(`   ✓ Client Title: "${clientTitle}", Subtitle: "${clientSubtitle}"`);
        console.log(`   ✓ Back button text: "${clientBackText}"`);
        console.log(`   ✓ Client Revenue: "${clientRev}", Qty: "${clientQty}"`);

        if (!clientTitle.includes('Покупки клієнта') || !clientBackText.includes('клієнта') || !clientRev.includes('млн ₴')) {
            throw new Error(`Client matrix data mismatch: title=${clientTitle}, rev=${clientRev}`);
        }

        const clientCardDisplay2 = await page.$eval('.kpi-bought', el => window.getComputedStyle(el).display);
        if (clientCardDisplay2 === 'none') {
            throw new Error(`kpi-bought should be visible in client mode`);
        }
        console.log(`   ✓ Client KPI cards visible and populated`);
        passedTests++; // Test 2

        console.log('=== TEST 3: Matrix Grid Rendering & Cell Click ===');
        await page.waitForSelector('.size-matrix');
        const cellCount = await page.$$eval('.size-matrix td.size-cell', cells => cells.length);
        const boughtCells = await page.$$eval('.size-matrix td.cell-bought', cells => cells.length);
        console.log(`   ✓ Total rendered matrix cells: ${cellCount}, Bought cells: ${boughtCells}`);

        if (cellCount === 0 || boughtCells === 0) {
            throw new Error(`Matrix grid not rendered properly: cells=${cellCount}, bought=${boughtCells}`);
        }
        passedTests++; // Test 3

        console.log('=== TEST 4: View Toggle (Grid / List) ===');
        // Click "Список"
        await page.click('#viewBtnList');
        await page.waitForFunction(() => {
            const listEl = document.getElementById('listContainer');
            return listEl && window.getComputedStyle(listEl).display !== 'none';
        }, { timeout: 10000 });

        await page.waitForFunction(() => {
            const tbody = document.getElementById('productsListBody');
            return tbody && tbody.querySelectorAll('tr').length > 0;
        }, { timeout: 10000 });

        const listRowsCount = await page.$$eval('#productsListBody tr', rows => rows.length);
        const listTotalText = await page.$eval('#listTotalCount', el => el.textContent.trim());
        console.log(`   ✓ Switched to list view: ${listRowsCount} rows loaded, total: ${listTotalText}`);

        if (listRowsCount === 0) {
            throw new Error('List view has 0 rows');
        }

        // Switch back to "Сітка"
        await page.click('#viewBtnGrid');
        await page.waitForFunction(() => {
            const gridEl = document.getElementById('matrixGrid');
            return gridEl && window.getComputedStyle(gridEl).display !== 'none';
        }, { timeout: 10000 });
        console.log(`   ✓ Switched back to grid view successfully`);
        passedTests++; // Test 4

        console.log('=== TEST 5: HTTP Redirects Verification ===');
        // Test redirect 1: /client-size-matrix -> /size-matrix
        const redirectRes1 = await page.goto('http://localhost:5000/client-size-matrix?token=utsk2026&code=4501&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });
        const finalUrl1 = page.url();
        console.log(`   ✓ /client-size-matrix redirected to: ${finalUrl1}`);
        if (!finalUrl1.includes('/size-matrix') || !finalUrl1.includes('from=client')) {
            throw new Error(`Redirect 1 failed: ${finalUrl1}`);
        }

        // Test redirect 2: /diversity-index -> /size-matrix
        const redirectRes2 = await page.goto('http://localhost:5000/diversity-index?token=utsk2026&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });
        const finalUrl2 = page.url();
        console.log(`   ✓ /diversity-index redirected to: ${finalUrl2}`);
        if (!finalUrl2.includes('/size-matrix') || !finalUrl2.includes('from=dashboard')) {
            throw new Error(`Redirect 2 failed: ${finalUrl2}`);
        }
        passedTests++; // Test 5

        console.log('=== TEST 6: Updated Links in Existing Pages ===');
        // 6.1 Check sidebar in index.html
        await page.goto('http://localhost:5000/?token=utsk2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });
        const sidebarLinkHref = await page.$eval('a[href*="size-matrix"]', el => el.getAttribute('href'));
        console.log(`   ✓ index.html sidebar matrix link: ${sidebarLinkHref}`);
        if (!sidebarLinkHref.includes('/size-matrix')) {
            throw new Error(`Sidebar link in index.html not updated: ${sidebarLinkHref}`);
        }

        // 6.2 Check product-analytics.html diversity button
        await page.goto('http://localhost:5000/product-analytics?token=utsk2026&code=4501&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });
        const diversityBtnHref = await page.$eval('#btn-diversity-matrix', el => el.getAttribute('href'));
        console.log(`   ✓ product-analytics.html diversity link: ${diversityBtnHref}`);
        if (!diversityBtnHref.includes('/size-matrix')) {
            throw new Error(`product-analytics link not updated: ${diversityBtnHref}`);
        }
        passedTests++; // Test 6

        console.log('=== TEST 7: Cell Navigation to /size-detail ===');
        await page.goto('http://localhost:5000/size-matrix?token=utsk2026&code=4501&year=2026&from=client', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });
        await page.waitForSelector('td.cell-bought');
        await Promise.all([
            page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 15000 }),
            page.click('td.cell-bought')
        ]);
        const sizeDetailUrl = page.url();
        console.log(`   ✓ Navigated from matrix cell to: ${sizeDetailUrl}`);
        if (!sizeDetailUrl.includes('/size-detail') || !sizeDetailUrl.includes('size_key=')) {
            throw new Error(`Cell navigation failed: ${sizeDetailUrl}`);
        }
        passedTests++; // Test 7

        // ─── CAPTURING SCREENSHOTS ───
        console.log('=== CAPTURING SCREENSHOTS ===');
        const screenshotsDir = path.join(__dirname, 'reports', 'screenshots');
        if (!fs.existsSync(screenshotsDir)) {
            fs.mkdirSync(screenshotsDir, { recursive: true });
        }

        // 1. General mode (no client)
        await page.goto('http://localhost:5000/size-matrix?token=utsk2026&year=2026&from=dashboard', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });
        await page.waitForFunction(() => document.getElementById('kpiCatalogPositions')?.textContent.trim() !== '—');
        const screenGenPath = path.join(screenshotsDir, 'size_matrix_general.png');
        await page.screenshot({ path: screenGenPath, fullPage: false });
        console.log(`   ✓ Saved general matrix screenshot: ${screenGenPath}`);

        // 2. Client mode (code=4501)
        await page.goto('http://localhost:5000/size-matrix?token=utsk2026&code=4501&year=2026&from=client', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });
        await page.waitForFunction(() => document.getElementById('kpiClientRevenue')?.textContent.trim() !== '—');
        const screenClientPath = path.join(screenshotsDir, 'size_matrix_client.png');
        await page.screenshot({ path: screenClientPath, fullPage: false });
        console.log(`   ✓ Saved client matrix screenshot: ${screenClientPath}`);

        // 3. List view
        await page.click('#viewBtnList');
        await page.waitForFunction(() => {
            const tbody = document.getElementById('productsListBody');
            return tbody && tbody.querySelectorAll('tr').length > 0;
        }, { timeout: 10000 });
        const screenListPath = path.join(screenshotsDir, 'size_matrix_list.png');
        await page.screenshot({ path: screenListPath, fullPage: false });
        console.log(`   ✓ Saved list view screenshot: ${screenListPath}`);

        // Copy screenshots to artifact directory
        const artifactDir = '/home/serg/.gemini/antigravity-cli/brain/66522b3e-08da-482f-8cd0-45d04ef6ffb0';
        if (fs.existsSync(artifactDir)) {
            fs.copyFileSync(screenGenPath, path.join(artifactDir, 'size_matrix_general.png'));
            fs.copyFileSync(screenClientPath, path.join(artifactDir, 'size_matrix_client.png'));
            fs.copyFileSync(screenListPath, path.join(artifactDir, 'size_matrix_list.png'));
            console.log(`   ✓ Screenshots copied to artifact directory: ${artifactDir}`);
        }

        console.log('\n========================================');
        console.log(`BASELINE METRICS RESULT: ${passedTests}/${totalTests} PASSED`);
        console.log(`CONSOLE ERRORS: ${errors.length}`);
        if (errors.length > 0) {
            console.error('Console errors detected:', errors);
            process.exit(1);
        }
        console.log('ALL VERIFICATION TESTS COMPLETED SUCCESSFULLY! ✓');
        console.log('========================================');

    } catch (e) {
        console.error('Verification failed with error:', e);
        if (errors.length > 0) {
            console.error('Console errors:', errors);
        }
        process.exit(1);
    } finally {
        await browser.close();
    }
})();
