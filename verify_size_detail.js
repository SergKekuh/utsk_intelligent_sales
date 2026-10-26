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
        console.log('=== TEST 1: Page Load & Basic Elements (/size-detail) ===');
        await page.goto('http://localhost:5000/size-detail?token=utsk2026&code=4501&size_key=round_140x10&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });

        // Check header title and category (wait for async fetch to finish)
        await page.waitForFunction(() => {
            const el = document.getElementById('sizeTitle');
            return el && el.textContent.trim() !== '—';
        }, { timeout: 10000 });
        const sizeTitle = await page.$eval('#sizeTitle', el => el.textContent.trim());
        const categoryBadge = await page.$eval('#categoryBadge', el => el.textContent.trim());
        console.log(`   ✓ sizeTitle: "${sizeTitle}", categoryBadge: "${categoryBadge}"`);
        if (sizeTitle !== '140×10' || categoryBadge !== 'Кругла') {
            throw new Error(`Unexpected header: title=${sizeTitle}, category=${categoryBadge}`);
        }
        passedTests++; // Metric 1

        console.log('=== TEST 2: Header KPIs & Breadcrumbs ===');
        const kpiSize = await page.$eval('#kpiSize', el => el.textContent.trim());
        const kpiStandards = await page.$eval('#kpiStandards', el => el.textContent.trim());
        const kpiStock = await page.$eval('#kpiStock', el => el.textContent.trim());
        const kpiClient = await page.$eval('#kpiClient', el => el.textContent.trim());
        const bcSize = await page.$eval('#bcSize', el => el.textContent.trim());

        console.log(`   ✓ KPIs: Size=${kpiSize}, Standards=${kpiStandards}, Stock=${kpiStock}, Client=${kpiClient}, Breadcrumb=${bcSize}`);
        if (!kpiStock.includes('т') || !kpiStandards.includes('поз.')) {
            throw new Error(`KPI values not formatted properly`);
        }
        passedTests++; // Metric 2

        console.log('=== TEST 3: VNITI Button for round_* size ===');
        const vnitiDisplay = await page.$eval('#vnitiBtn', el => window.getComputedStyle(el).display);
        const vnitiHref = await page.$eval('#vnitiBtn', el => el.getAttribute('href'));
        console.log(`   ✓ VNITI button display: "${vnitiDisplay}", href: "${vnitiHref}"`);
        if (vnitiDisplay === 'none' || !vnitiHref.includes('/billet-detail')) {
            throw new Error(`VNITI button should be visible with link to billet-detail`);
        }
        passedTests++; // Metric 3

        console.log('=== TEST 4: Product Tabs & Content Rendering ===');
        const tabBtns = await page.$$eval('.tab-btn', els => els.map(e => e.textContent.replace(/\s+/g, ' ').trim()));
        console.log(`   ✓ Rendered tabs (${tabBtns.length}):`, tabBtns);
        if (tabBtns.length < 2) {
            throw new Error(`Expected at least 2 tabs for round_140x10, got ${tabBtns.length}`);
        }

        // Check active tab content
        const firstTabCode = await page.$eval('.info-table td.code-cell', el => el.textContent.trim());
        const steelGrade = await page.$eval('.info-table tr:nth-child(4) td:nth-child(2)', el => el.textContent.trim());
        const clientStatus = await page.$eval('.status-badge', el => el.textContent.trim());
        console.log(`   ✓ Product Code: "${firstTabCode}", Steel Grade: "${steelGrade}", Client Status: "${clientStatus}"`);
        if (steelGrade !== 'ст20') {
            throw new Error(`Expected steel grade 'ст20', got '${steelGrade}'`);
        }
        passedTests++; // Metric 4

        console.log('=== TEST 5: Interactive Tab Switching ===');
        // Click second tab
        await page.click('.tab-btn[data-index="1"]');
        await new Promise(r => setTimeout(r, 400));
        const activeIndex = await page.$eval('.tab-btn.active', el => el.getAttribute('data-index'));
        const secondTabCode = await page.$eval('.info-table td.code-cell', el => el.textContent.trim());
        console.log(`   ✓ Switched to tab ${activeIndex}, Product Code: "${secondTabCode}"`);
        if (activeIndex !== '1' || secondTabCode === firstTabCode) {
            throw new Error(`Tab switching failed: activeIndex=${activeIndex}, code=${secondTabCode}`);
        }
        passedTests++; // Metric 5

        console.log('=== TEST 6: Profile Size & VNITI Button Hidden ===');
        await page.goto('http://localhost:5000/size-detail?token=utsk2026&code=4501&size_key=prof_100x100x4&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });
        await page.waitForFunction(() => {
            const el = document.getElementById('categoryBadge');
            return el && el.textContent.trim() !== '—';
        }, { timeout: 10000 });
        const profCategory = await page.$eval('#categoryBadge', el => el.textContent.trim());
        const profVnitiDisplay = await page.$eval('#vnitiBtn', el => window.getComputedStyle(el).display);
        console.log(`   ✓ profCategory: "${profCategory}", VNITI button display: "${profVnitiDisplay}"`);
        if (profCategory !== 'Профільна' || profVnitiDisplay !== 'none') {
            throw new Error(`Profile size check failed: category=${profCategory}, vnitiDisplay=${profVnitiDisplay}`);
        }
        passedTests++; // Metric 6

        console.log('=== TEST 7: Matrix Click -> Direct Navigation to /size-detail (No Modal) ===');
        await page.goto('http://localhost:5000/client-size-matrix?token=utsk2026&code=4501&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 20000
        });
        await page.waitForSelector('.size-cell.cell-bought');

        // Check that drillModal does NOT exist in DOM
        const drillModalExists = await page.$('#drillModal');
        if (drillModalExists) {
            throw new Error('#drillModal element still exists in DOM');
        }

        // Click a bought cell and check URL navigation
        await Promise.all([
            page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 15000 }),
            page.click('.size-cell.cell-bought')
        ]);
        const currentUrl = page.url();
        console.log(`   ✓ Navigated to: ${currentUrl}`);
        if (!currentUrl.includes('/size-detail')) {
            throw new Error(`Clicking matrix cell did not navigate to /size-detail: ${currentUrl}`);
        }
        passedTests++; // Metric 7

        // Return to round_140x10 to capture screenshots
        console.log('=== CAPTURING SCREENSHOTS ===');
        await page.goto('http://localhost:5000/size-detail?token=utsk2026&code=4501&size_key=round_140x10&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });
        await page.waitForFunction(() => {
            const el = document.getElementById('sizeTitle');
            return el && el.textContent.trim() !== '—';
        }, { timeout: 10000 });

        const screenshotsDir = path.join(__dirname, 'reports', 'screenshots');
        if (!fs.existsSync(screenshotsDir)) {
            fs.mkdirSync(screenshotsDir, { recursive: true });
        }

        const fullPath = path.join(screenshotsDir, 'size_detail_full.png');
        const headerPath = path.join(screenshotsDir, 'size_detail_header.png');
        const tabsPath = path.join(screenshotsDir, 'size_detail_tabs.png');

        await page.screenshot({ path: fullPath, fullPage: true });
        console.log(`   ✓ Full screenshot saved: ${fullPath}`);

        const headerEl = await page.$('.header-card');
        if (headerEl) {
            await headerEl.screenshot({ path: headerPath });
            console.log(`   ✓ Header screenshot saved: ${headerPath}`);
        }

        const tabsEl = await page.$('.tabs-card');
        if (tabsEl) {
            await tabsEl.screenshot({ path: tabsPath });
            console.log(`   ✓ Tabs screenshot saved: ${tabsPath}`);
        }

        // Also copy screenshots to artifact dir if present
        const artifactDir = '/home/serg/.gemini/antigravity-cli/brain/66522b3e-08da-482f-8cd0-45d04ef6ffb0';
        if (fs.existsSync(artifactDir)) {
            fs.copyFileSync(fullPath, path.join(artifactDir, 'size_detail_full.png'));
            fs.copyFileSync(headerPath, path.join(artifactDir, 'size_detail_header.png'));
            fs.copyFileSync(tabsPath, path.join(artifactDir, 'size_detail_tabs.png'));
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
