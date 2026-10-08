const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
        headless: "new"
    });
    const page = await browser.newPage();
    await page.setViewport({ width: 1560, height: 1000 });

    const consoleErrors = [];
    page.on('console', msg => {
        if (msg.type() === 'error') {
            consoleErrors.push(msg.text());
        }
    });
    page.on('pageerror', err => {
        consoleErrors.push(err.toString());
    });

    console.log("Navigating to /client-size-matrix?token=utsk2026&code=4501&year=2026...");
    await page.goto('http://localhost:5000/client-size-matrix?token=utsk2026&code=4501&year=2026', {
        waitUntil: 'networkidle0',
        timeout: 30000
    });

    // Wait for table
    await page.waitForSelector('#matrixContainer table', { timeout: 10000 });

    // 1. Check KPI cards
    const kpiData = await page.evaluate(() => {
        return {
            catalogPositions: document.getElementById('kpiCatalogPositions').innerText,
            catalogSizes: document.getElementById('kpiCatalogSizes').innerText,
            catalogSizesSub: document.getElementById('kpiCatalogSizesSub').innerText,
            clientBought: document.getElementById('kpiClientBought').innerText,
            clientBoughtSub: document.getElementById('kpiClientBoughtSub').innerText,
            clientRevenue: document.getElementById('kpiClientRevenue').innerText,
            clientQty: document.getElementById('kpiClientQty').innerText,
            stockSizes: document.getElementById('kpiStockSizes').innerText,
        };
    });
    console.log("=== KPI CARDS ===");
    console.log(JSON.stringify(kpiData, null, 2));

    // 2. Tab 1: Round
    let statsRound = await page.evaluate(() => {
        const stats = document.getElementById('legendStatsText').innerText;
        const thFirst = document.querySelector('#matrixContainer thead th').innerText;
        const rows = document.querySelectorAll('#matrixContainer tbody tr').length;
        const cols = document.querySelectorAll('#matrixContainer thead th').length;
        return { stats, thFirst, rows, cols };
    });
    console.log("\n=== TAB 1: ROUND ===");
    console.log(statsRound);
    await page.screenshot({ path: 'tab_1_round.png' });

    // 3. Tab 2: Prof
    await page.click('#btn-toggle-prof');
    await new Promise(r => setTimeout(r, 600));
    let statsProf = await page.evaluate(() => {
        const stats = document.getElementById('legendStatsText').innerText;
        const thFirst = document.querySelector('#matrixContainer thead th').innerText;
        const rows = document.querySelectorAll('#matrixContainer tbody tr').length;
        const cols = document.querySelectorAll('#matrixContainer thead th').length;
        return { stats, thFirst, rows, cols };
    });
    console.log("\n=== TAB 2: PROF ===");
    console.log(statsProf);
    await page.screenshot({ path: 'tab_2_prof.png' });

    // 4. Tab 3: Welded
    await page.click('#btn-toggle-welded');
    await new Promise(r => setTimeout(r, 600));
    let statsWelded = await page.evaluate(() => {
        const stats = document.getElementById('legendStatsText').innerText;
        const thFirst = document.querySelector('#matrixContainer thead th').innerText;
        const rows = document.querySelectorAll('#matrixContainer tbody tr').length;
        const cols = document.querySelectorAll('#matrixContainer thead th').length;
        return { stats, thFirst, rows, cols };
    });
    console.log("\n=== TAB 3: WELDED ===");
    console.log(statsWelded);
    await page.screenshot({ path: 'tab_3_welded.png' });

    // 5. Tab 4: Sheet
    await page.click('#btn-toggle-sheet');
    await new Promise(r => setTimeout(r, 600));
    let statsSheet = await page.evaluate(() => {
        const stats = document.getElementById('legendStatsText').innerText;
        const thFirst = document.querySelector('#matrixContainer thead th').innerText;
        const rows = document.querySelectorAll('#matrixContainer tbody tr').length;
        const cols = document.querySelectorAll('#matrixContainer thead th').length;
        return { stats, thFirst, rows, cols };
    });
    console.log("\n=== TAB 4: SHEET ===");
    console.log(statsSheet);
    await page.screenshot({ path: 'tab_4_sheet.png' });

    console.log("\n=== CONSOLE ERRORS ===");
    console.log(`Console error count: ${consoleErrors.length}`);
    if (consoleErrors.length > 0) {
        consoleErrors.forEach((e, i) => console.log(`  ${i+1}: ${e}`));
    }

    await browser.close();

    if (consoleErrors.length > 0) {
        process.exit(1);
    } else {
        console.log("\nALL PUPPETEER TAB TESTS PASSED WITH 0 ERRORS!");
    }
})();
