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

    try {
        console.log('--- TEST 1: Page Load & Block 4 ESKD Schemas ---');
        await page.goto('http://localhost:5000/billet-detail?token=utsk2026&code=4501&size_key=round_50x4&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });

        // 1. Verify Scheme 1 has ESKD elements: H, B, T, C1, C2, 5°, hatchPattern, >= 100 мм
        console.log('--- TEST 2: Verify Scheme 1 (ESKD cross-section) ---');
        const scheme1Html = await page.$eval('#schema1Svg', el => el.outerHTML);
        const scheme1CardText = await page.$eval('.tolerance-card:nth-child(1)', el => el.innerText);

        const scheme1Requirements = [
            { name: 'Dimension H', test: scheme1Html.includes('>H<') },
            { name: 'Dimension B', test: scheme1Html.includes('>B<') },
            { name: 'Thickness T', test: scheme1Html.includes('>T<') },
            { name: 'Corner chamfer C₁', test: scheme1Html.includes('C₁') },
            { name: 'Corner chamfer C₂', test: scheme1Html.includes('C₂') },
            { name: 'Angle 5°', test: scheme1Html.includes('5°') },
            { name: 'Measurement base ≥ 100 mm', test: scheme1Html.includes('≥ 100 мм') || scheme1CardText.includes('≥ 100 мм') },
            { name: 'Pattern hatchPattern', test: scheme1Html.includes('id="hatchPattern"') },
            { name: 'Markers arrowStart/End', test: scheme1Html.includes('id="arrowStart"') && scheme1Html.includes('id="arrowEnd"') },
            { name: 'ESKD contour class', test: scheme1Html.includes('class="contour"') },
            { name: 'ESKD hatch class', test: scheme1Html.includes('class="hatch"') }
        ];

        for (const req of scheme1Requirements) {
            if (!req.test) {
                throw new Error(`Scheme 1 requirement failed: ${req.name}`);
            }
            console.log(`   ✓ Scheme 1 requirement passed: ${req.name}`);
        }

        // 2. Verify Scheme 7 has moments Ix, Iy, Wx, Wy, axes Y-Y, Z-Z, center (0,0)
        console.log('--- TEST 3: Verify Scheme 7 (Principal axes and moments) ---');
        const scheme7Card = await page.$eval('.tolerance-card:nth-child(7)', el => el.innerHTML);

        const scheme7Requirements = [
            { name: 'Axis Y-Y', test: scheme7Card.includes('Y-Y') },
            { name: 'Axis Z-Z', test: scheme7Card.includes('Z-Z') },
            { name: 'Moment of inertia Iₓ', test: scheme7Card.includes('Iₓ') },
            { name: 'Moment of inertia I_y', test: scheme7Card.includes('I_y') },
            { name: 'Section modulus Wₓ', test: scheme7Card.includes('Wₓ') },
            { name: 'Section modulus W_y', test: scheme7Card.includes('W_y') },
            { name: 'Center (0,0)', test: scheme7Card.includes('(0,0)') },
            { name: 'Metal hatch', test: scheme7Card.includes('class="hatch"') }
        ];

        for (const req of scheme7Requirements) {
            if (!req.test) {
                throw new Error(`Scheme 7 requirement failed: ${req.name}`);
            }
            console.log(`   ✓ Scheme 7 requirement passed: ${req.name}`);
        }

        // 3. Verify Lightbox for Scheme 1 and Scheme 7
        console.log('--- TEST 4: Lightbox Interaction for Scheme 1 and Scheme 7 ---');
        const lightbox = await page.$('#svgLightbox');
        if (!lightbox) throw new Error('#svgLightbox modal not found');

        // Test Lightbox on Card 1
        await page.click('.tolerance-card:nth-child(1)');
        await page.waitForFunction(() => {
            const lb = document.getElementById('svgLightbox');
            return lb && window.getComputedStyle(lb).display !== 'none';
        }, { timeout: 3000 });
        console.log('   ✓ Lightbox successfully opened for Scheme 1');

        await page.keyboard.press('Escape');
        await page.waitForFunction(() => {
            const lb = document.getElementById('svgLightbox');
            return lb && window.getComputedStyle(lb).display === 'none';
        }, { timeout: 3000 });
        console.log('   ✓ Lightbox closed via Escape');

        // Test Lightbox on Card 7
        await page.click('.tolerance-card:nth-child(7)');
        await page.waitForFunction(() => {
            const lb = document.getElementById('svgLightbox');
            return lb && window.getComputedStyle(lb).display !== 'none';
        }, { timeout: 3000 });
        console.log('   ✓ Lightbox successfully opened for Scheme 7');

        await page.keyboard.press('Escape');
        await page.waitForFunction(() => {
            const lb = document.getElementById('svgLightbox');
            return lb && window.getComputedStyle(lb).display === 'none';
        }, { timeout: 3000 });
        console.log('   ✓ Lightbox closed via Escape');

        // 4. Capture 4 screenshots
        console.log('--- TEST 5: Capture Screenshots ---');
        const reportsDir = path.join(__dirname, 'reports', 'screenshots');
        fs.mkdirSync(reportsDir, { recursive: true });
        const artifactDir = '/home/serg/.gemini/antigravity-cli/brain/77ffe540-0ab7-4aa1-8395-dedd8b90c795';

        const fullPath = path.join(reportsDir, 'iteration4_2_full.png');
        const block4Path = path.join(reportsDir, 'iteration4_2_block4.png');
        const scheme1Path = path.join(reportsDir, 'iteration4_2_scheme1.png');
        const scheme7Path = path.join(reportsDir, 'iteration4_2_scheme7.png');

        // Full page
        await page.screenshot({ path: fullPath, fullPage: true });
        console.log(`   ✓ Saved: ${fullPath}`);

        // Block 4
        const block4El = await page.$('#block4Container');
        if (block4El) {
            await block4El.screenshot({ path: block4Path });
            console.log(`   ✓ Saved: ${block4Path}`);
        }

        // Scheme 1
        const card1El = await page.$('.tolerance-card:nth-child(1)');
        if (card1El) {
            await card1El.screenshot({ path: scheme1Path });
            console.log(`   ✓ Saved: ${scheme1Path}`);
        }

        // Scheme 7
        const card7El = await page.$('.tolerance-card:nth-child(7)');
        if (card7El) {
            await card7El.screenshot({ path: scheme7Path });
            console.log(`   ✓ Saved: ${scheme7Path}`);
        }

        // Copy to artifact directory
        fs.copyFileSync(fullPath, path.join(artifactDir, 'iteration4_2_full.png'));
        fs.copyFileSync(block4Path, path.join(artifactDir, 'iteration4_2_block4.png'));
        fs.copyFileSync(scheme1Path, path.join(artifactDir, 'iteration4_2_scheme1.png'));
        fs.copyFileSync(scheme7Path, path.join(artifactDir, 'iteration4_2_scheme7.png'));
        console.log(`   ✓ Copied all 4 screenshots to artifact dir: ${artifactDir}`);

        // 5. Console errors check
        console.log('--- TEST 6: Console Errors Check ---');
        if (errors.length > 0) {
            console.error('Console errors detected:', errors);
            throw new Error(`Encountered ${errors.length} console errors`);
        } else {
            console.log('   ✓ 0 console errors detected');
        }

        console.log('\n========================================');
        console.log('🎉 ALL PUPPETEER VERIFICATION TESTS PASSED!');
        console.log('========================================\n');

    } catch (err) {
        console.error('❌ Verification failed:', err);
        process.exit(1);
    } finally {
        await browser.close();
    }
})();
