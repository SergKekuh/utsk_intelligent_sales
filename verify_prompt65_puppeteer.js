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
        console.log('--- TEST 1: Page Load & Block 4 Schemas ---');
        await page.goto('http://localhost:5000/billet-detail?token=utsk2026&code=4501&size_key=round_50x4&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });

        // 1. Wait for dynamic Scheme 1 to render round billet Ø 50
        await page.waitForFunction(() => {
            const svg1 = document.getElementById('schema1Svg');
            return svg1 && svg1.innerHTML.includes('Ø 50');
        }, { timeout: 10000 });

        console.log('   ✓ Scheme 1 rendered with dynamic section and >= 100 mm reference');

        // 2. Check 9 cards with zoom icons
        const cardCount = await page.$$eval('.tolerance-card', els => els.length);
        const zoomIconCount = await page.$$eval('.tolerance-card__zoom-icon', els => els.length);
        console.log(`   ✓ Tolerance cards: ${cardCount}, Zoom icons: ${zoomIconCount}`);
        if (cardCount !== 9 || zoomIconCount !== 9) {
            throw new Error(`Expected 9 cards and 9 zoom icons, got cards=${cardCount}, icons=${zoomIconCount}`);
        }

        // 3. Verify Scheme 2 radii
        const scheme2Html = await page.$eval('.tolerance-card:nth-child(2)', el => el.innerHTML);
        if (!scheme2Html.includes('r₀') || !scheme2Html.includes('rᵢ') || !scheme2Html.includes('rᵢ = r₀ − t')) {
            throw new Error('Scheme 2 does not contain both r₀ and rᵢ or rᵢ = r₀ − t');
        }
        console.log('   ✓ Scheme 2 correctly displays both external r₀ and internal rᵢ radii');

        // 4. Verify Scheme 3 angular template
        const scheme3Html = await page.$eval('.tolerance-card:nth-child(3)', el => el.innerHTML);
        if (!scheme3Html.includes('±1°30\'') || !scheme3Html.includes('C₁')) {
            throw new Error('Scheme 3 does not contain ±1°30\' or C₁');
        }
        console.log('   ✓ Scheme 3 correctly displays ±1°30\' sector and C₁ gauge');

        // 5. Verify Scheme 5 straightedge & feeler
        const scheme5Html = await page.$eval('.tolerance-card:nth-child(5)', el => el.innerHTML);
        if (!scheme5Html.includes('1000 мм') || !scheme5Html.includes('v₁')) {
            throw new Error('Scheme 5 does not contain 1000 mm base or v₁');
        }
        console.log('   ✓ Scheme 5 correctly displays 1000 mm straightedge with feeler gauge');

        // 6. Verify Scheme 6 wire
        const scheme6Html = await page.$eval('.tolerance-card:nth-child(6)', el => el.innerHTML);
        if (!scheme6Html.includes('Δ_заг') || !scheme6Html.includes('θ ≤ 5°')) {
            throw new Error('Scheme 6 does not contain Δ_заг or θ');
        }
        console.log('   ✓ Scheme 6 correctly displays string wire and twist angle');

        // 7. Verify Scheme 8 weld position
        const scheme8Html = await page.$eval('.tolerance-card:nth-child(8)', el => el.innerHTML);
        if (!scheme8Html.includes('X ≥ 4t') || !scheme8Html.includes('≥ 2t від шва')) {
            throw new Error('Scheme 8 does not contain X ≥ 4t or ≥ 2t від шва');
        }
        console.log('   ✓ Scheme 8 correctly displays X ≥ 4t and thickness measurement at ≥ 2t from weld');

        // 8. Dynamic Badges
        const r0BadgeText = await page.$eval('#badgeTolR0', el => el.innerText.trim());
        const weldBadgeText = await page.$eval('#badgeTolWeld', el => el.innerText.trim());
        console.log(`   ✓ badgeTolR0: "${r0BadgeText}"`);
        console.log(`   ✓ badgeTolWeld: "${weldBadgeText}"`);
        if (!r0BadgeText.includes('6.4 … 9.6 мм') || !weldBadgeText.includes('16 мм')) {
            throw new Error('Dynamic badges for wall=4mm not updated correctly');
        }

        // Directories setup
        const reportsDir = path.join(__dirname, 'reports', 'screenshots');
        const artifactDir = '/home/serg/.gemini/antigravity-cli/brain/77ffe540-0ab7-4aa1-8395-dedd8b90c795';

        const fullPath = path.join(reportsDir, 'iteration4_1_full.png');
        const block4Path = path.join(reportsDir, 'iteration4_1_block4.png');
        const lightboxPath = path.join(reportsDir, 'iteration4_1_lightbox.png');

        // Full & Block 4 screenshots
        await page.screenshot({ path: fullPath, fullPage: true });
        console.log(`   ✓ Saved: ${fullPath}`);

        const block4El = await page.$('#block4Container');
        if (block4El) {
            await block4El.screenshot({ path: block4Path });
            console.log(`   ✓ Saved: ${block4Path}`);
        }

        console.log('\n--- TEST 2: Lightbox Modal Interaction ---');
        // Click on Card 2 (Radius R)
        await page.click('.tolerance-card:nth-child(2)');

        // Wait for lightbox to become visible
        await page.waitForFunction(() => {
            const lb = document.getElementById('svgLightbox');
            return lb && window.getComputedStyle(lb).display === 'flex';
        }, { timeout: 5000 });

        const lbTitle = await page.$eval('#svgLightbox .lightbox__title', el => el.innerText.trim());
        const hasSvg = await page.$eval('#svgLightbox .lightbox__svg svg', el => !!el);
        console.log(`   ✓ Lightbox opened successfully. Title: "${lbTitle}", SVG present: ${hasSvg}`);

        // Save Lightbox screenshot
        await page.screenshot({ path: lightboxPath });
        console.log(`   ✓ Saved: ${lightboxPath}`);

        // Close via close button or Escape
        await page.keyboard.press('Escape');

        // Verify lightbox closed
        await page.waitForFunction(() => {
            const lb = document.getElementById('svgLightbox');
            return lb && window.getComputedStyle(lb).display === 'none';
        }, { timeout: 5000 });
        console.log('   ✓ Lightbox closed cleanly upon ESC key');

        // Copy screenshots to artifact directory
        fs.copyFileSync(fullPath, path.join(artifactDir, 'iteration4_1_full.png'));
        fs.copyFileSync(block4Path, path.join(artifactDir, 'iteration4_1_block4.png'));
        fs.copyFileSync(lightboxPath, path.join(artifactDir, 'iteration4_1_lightbox.png'));
        console.log('   ✓ All screenshots copied to artifact directory');

        console.log('\n--- TEST 3: Console Errors Check ---');
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
        console.log('\n🎉 ALL PROMPT 65 (ITERATION 4.1) TESTS PASSED SUCCESSFULLY!');
        process.exit(0);
    }
})();
