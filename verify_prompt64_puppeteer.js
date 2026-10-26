const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

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
        console.log('--- TEST 1: Page load & DOM elements check ---');
        await page.goto('http://localhost:5000/billet-detail?token=utsk2026&code=4501&size_key=round_50x4&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });

        // 1. Check target profile from Prompt 63
        await page.waitForFunction(() => {
            const el = document.getElementById('targetProfile');
            return el && el.textContent.includes('40×40×4');
        }, { timeout: 10000 });

        console.log('   ✓ Block 2 Target profile is 40×40×4');

        // 2. Check 9 SVG schemas in Block 4
        const svgCount = await page.$$eval('#block4Container .tolerance-card__svg', els => els.length);
        console.log(`   ✓ Found ${svgCount} SVG schemas in Block 4`);
        if (svgCount !== 9) {
            throw new Error(`Expected 9 SVG schemas, found ${svgCount}`);
        }

        // 3. Verify Dynamic Badges
        const r0BadgeText = await page.$eval('#badgeTolR0', el => el.innerText.trim());
        const weldBadgeText = await page.$eval('#badgeTolWeld', el => el.innerText.trim());
        console.log(`   ✓ badgeTolR0: "${r0BadgeText}"`);
        console.log(`   ✓ badgeTolWeld: "${weldBadgeText}"`);

        if (!r0BadgeText.includes('6.4 … 9.6 мм')) {
            throw new Error(`Expected badgeTolR0 to contain '6.4 … 9.6 мм', got '${r0BadgeText}'`);
        }
        if (!weldBadgeText.includes('16 мм') || !weldBadgeText.includes('0.5 мм')) {
            throw new Error(`Expected badgeTolWeld to contain '16 мм' and '0.5 мм', got '${weldBadgeText}'`);
        }

        // 4. Capture Screenshots
        const reportsDir = path.join(__dirname, 'reports', 'screenshots');
        const artifactDir = '/home/serg/.gemini/antigravity-cli/brain/77ffe540-0ab7-4aa1-8395-dedd8b90c795';

        const fullPath = path.join(reportsDir, 'iteration4_full.png');
        const block4Path = path.join(reportsDir, 'iteration4_block4.png');

        await page.screenshot({ path: fullPath, fullPage: true });
        console.log(`   ✓ Full screenshot saved to: ${fullPath}`);

        const block4El = await page.$('#block4Container');
        if (block4El) {
            await block4El.screenshot({ path: block4Path });
            console.log(`   ✓ Block 4 screenshot saved to: ${block4Path}`);
        } else {
            throw new Error('Could not find #block4Container for screenshot');
        }

        // Copy to artifact dir for embedding if needed
        fs.copyFileSync(fullPath, path.join(artifactDir, 'iteration4_full.png'));
        fs.copyFileSync(block4Path, path.join(artifactDir, 'iteration4_block4.png'));
        console.log(`   ✓ Screenshots copied to artifact directory`);

        console.log('\n--- TEST 2: Console Errors Check ---');
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
        console.log('\n🎉 ALL PROMPT 64 SVG TESTS PASSED SUCCESSFULLY!');
        process.exit(0);
    }
})();
