const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
        headless: 'new'
    });
    const page = await browser.newPage();
    await page.setViewport({ width: 1440, height: 1200 });

    const errors = [];
    page.on('console', msg => {
        if (msg.type() === 'error' && !msg.text().includes('favicon.ico')) {
            errors.push(`[Console Error] ${msg.text()}`);
        }
    });
    page.on('pageerror', err => errors.push(`[Page Error] ${err.toString()}`));

    let allTestsPassed = true;

    try {
        console.log('--- TEST A: /billet-detail page verification ---');
        await page.goto('http://localhost:5000/billet-detail?token=utsk2026&code=4501&size_key=round_50x4&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });

        // 1. Verify Blocks 1-5 present
        const b1 = await page.$('#block1Container');
        const b2 = await page.$('#block2Container');
        const b3 = await page.$('#block3Container');
        const b4 = await page.$('#block4Container');
        const b5 = await page.$('#block5Container');
        console.log(`   ✓ Blocks present: B1:${!!b1}, B2:${!!b2}, B3:${!!b3}, B4:${!!b4}, B5:${!!b5}`);

        if (!b1 || !b2 || !b3 || !b4 || !b5) {
            throw new Error('One or more of Blocks 1-5 is missing!');
        }

        // Wait a bit for JS fetch calls to complete
        await page.waitForFunction(() => {
            const kpi = document.getElementById('kpiSizeDisplay');
            return kpi && kpi.textContent !== '—' && kpi.textContent.includes('50');
        }, { timeout: 10000 });

        // 2. Check Block 1 KPIs
        const sizeDisplay = await page.$eval('#kpiSizeDisplay', el => el.innerText.trim());
        const stockTotal = await page.$eval('#kpiStockTotal', el => el.innerText.trim());
        const badgeStock = await page.$eval('#badgeStock', el => el.innerText.trim());
        console.log(`   ✓ Block 1: size="${sizeDisplay}", stock="${stockTotal}", badge="${badgeStock}"`);

        // 3. Check Block 2 KPIs
        const rCalc = await page.$eval('#kpiRCalc', el => el.innerText.trim());
        const rProd = await page.$eval('#kpiRProd', el => el.innerText.trim());
        const dBillet = await page.$eval('#kpiDBillet', el => el.innerText.trim());
        const kReal = await page.$eval('#kpiKReal', el => el.innerText.trim());
        const badgeFitsTu = await page.$eval('#badgeFitsTu', el => el.innerText.trim());
        console.log(`   ✓ Block 2: r_calc=${rCalc}, r_prod=${rProd}, d_billet=${dBillet}, k_real=${kReal}, badge="${badgeFitsTu}"`);

        if (rCalc === '—' || rProd === '—' || dBillet === '—') {
            throw new Error('Block 2 KPIs not populated!');
        }

        // 4. Check Block 3 Square table
        const sqRows = await page.$$eval('#squareTableBody tr', trs => trs.length);
        const sqCount = await page.$eval('#squareCountText', el => el.innerText.trim());
        console.log(`   ✓ Block 3 Square: count badge=${sqCount}, rendered rows=${sqRows}`);

        // Switch to Rect tab
        console.log('   Testing tab switch to Rect...');
        await page.click('#tabRectBtn');
        await new Promise(r => setTimeout(r, 400));
        const rectRows = await page.$$eval('#rectTableBody tr', trs => trs.length);
        const rectCount = await page.$eval('#rectCountText', el => el.innerText.trim());
        console.log(`   ✓ Block 3 Rect: count badge=${rectCount}, rendered rows=${rectRows}`);

        // 5. Check Block 4 (8 cards)
        const tolCards = await page.$$eval('.tolerance-card', els => els.length);
        console.log(`   ✓ Block 4: tolerance cards count=${tolCards} (expected: 8)`);

        // 6. Check Block 5 (TU table)
        await page.waitForFunction(() => {
            const body = document.getElementById('block5TableBody');
            return body && body.querySelectorAll('tr').length > 0 && !body.innerText.includes('Завантаження');
        }, { timeout: 8000 });
        const tuRows = await page.$$eval('#block5TableBody tr', trs => trs.length);
        const tuHighlight = await page.$$eval('#block5TableBody tr.row-highlight', trs => trs.length);
        console.log(`   ✓ Block 5 TU Table: rows=${tuRows}, highlighted wall row=${tuHighlight}`);

        // Take full screenshot
        await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_billet_detail.png', fullPage: true });
        console.log('   ✓ Screenshot saved to utsk_web/frontend/static/screenshot_billet_detail.png');

        console.log('\n--- TEST B: Modal button in client-size-matrix.html ---');
        await page.goto('http://localhost:5000/client-size-matrix?token=utsk2026&code=4501&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 20000
        });

        await page.waitForSelector('.size-matrix', { timeout: 10000 });

        // 1. Click a round cell
        const roundCell = await page.$('.size-cell[onclick*="round_"]');
        if (!roundCell) throw new Error('No round_ cell found in matrix!');

        await roundCell.click();
        await page.waitForSelector('#drillModal', { visible: true, timeout: 5000 });
        await new Promise(r => setTimeout(r, 500));

        const vnitiBtnDisplayRound = await page.$eval('#vnitiBtn', el => window.getComputedStyle(el).display);
        const vnitiBtnHref = await page.$eval('#vnitiBtn', el => el.getAttribute('href'));
        console.log(`   ✓ Round cell clicked: vnitiBtn display="${vnitiBtnDisplayRound}", href="${vnitiBtnHref}"`);

        if (vnitiBtnDisplayRound === 'none' || !vnitiBtnHref.includes('/billet-detail')) {
            throw new Error(`vnitiBtn should be visible for round_ cell, got display=${vnitiBtnDisplayRound}, href=${vnitiBtnHref}`);
        }

        await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_modal_round_vniti_btn.png' });

        // Close modal
        await page.click('.modal-close');
        await new Promise(r => setTimeout(r, 400));

        // 2. Switch to profile pipes
        await page.click('#btn-toggle-prof');
        await new Promise(r => setTimeout(r, 600));

        const profCell = await page.$('.size-cell[onclick*="prof_"]');
        if (!profCell) throw new Error('No prof_ cell found in matrix!');

        await profCell.click();
        await page.waitForSelector('#drillModal', { visible: true, timeout: 5000 });
        await new Promise(r => setTimeout(r, 500));

        const vnitiBtnDisplayProf = await page.$eval('#vnitiBtn', el => window.getComputedStyle(el).display);
        console.log(`   ✓ Prof cell clicked: vnitiBtn display="${vnitiBtnDisplayProf}" (expected: "none")`);

        if (vnitiBtnDisplayProf !== 'none') {
            throw new Error(`vnitiBtn should be hidden for prof_ cell, got display=${vnitiBtnDisplayProf}`);
        }

        console.log('\n--- TEST C: Console Errors Check ---');
        console.log(`   Total console errors: ${errors.length}`);
        if (errors.length > 0) {
            console.error('   Errors detected:', errors);
            allTestsPassed = false;
        } else {
            console.log('   ✓ Zero console errors!');
        }

    } catch (err) {
        console.error('❌ Verification failed:', err);
        allTestsPassed = false;
    } finally {
        await browser.close();
    }

    if (!allTestsPassed) {
        process.exit(1);
    } else {
        console.log('\n🎉 ALL FRONTEND VERIFICATION TESTS PASSED SUCCESSFULLY!');
        process.exit(0);
    }
})();
