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
        console.log('--- TEST A: /billet-detail page verification (Prompt 63) ---');
        await page.goto('http://localhost:5000/billet-detail?token=utsk2026&code=4501&size_key=round_50x4&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });

        // Wait for Block 2 target profile to render
        await page.waitForFunction(() => {
            const el = document.getElementById('targetProfile');
            return el && el.textContent.includes('40×40×4');
        }, { timeout: 10000 });

        const targetProfileText = await page.$eval('#targetProfile', el => el.innerText.trim());
        const rCalc = await page.$eval('#kpiRCalc', el => el.innerText.trim());
        const rProd = await page.$eval('#kpiRProd', el => el.innerText.trim());
        const dBillet = await page.$eval('#kpiDBillet', el => el.innerText.trim());
        const kReal = await page.$eval('#kpiKReal', el => el.innerText.trim());
        const badgeFitsTu = await page.$eval('#badgeFitsTu', el => el.innerText.trim());

        console.log(`   ✓ Block 2 Target Profile: "${targetProfileText}"`);
        console.log(`   ✓ Block 2 KPIs: r_calc=${rCalc}, r_prod=${rProd}, d_billet=${dBillet}, k_real=${kReal}, badge="${badgeFitsTu}"`);

        if (targetProfileText !== '40×40×4') {
            throw new Error(`Expected targetProfile '40×40×4', got '${targetProfileText}'`);
        }
        if (!badgeFitsTu.includes('Відповідає нормам ТУ')) {
            throw new Error(`Expected badge to indicate TU match, got '${badgeFitsTu}'`);
        }

        // Take full screenshot
        await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_billet_detail.png', fullPage: true });
        console.log('   ✓ Screenshot saved to utsk_web/frontend/static/screenshot_billet_detail.png');

        console.log('\n--- TEST B: Console Errors Check ---');
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
        console.log('\n🎉 ALL PROMPT 63 TESTS PASSED SUCCESSFULLY!');
        process.exit(0);
    }
})();
