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
        console.log('=== TEST 1: Page Load & Header Elements (/diversity-index) ===');
        await page.goto('http://localhost:5000/diversity-index?token=utsk2026&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });

        await page.waitForFunction(() => {
            const el = document.getElementById('kpiTotal');
            return el && el.textContent.trim() !== '—';
        }, { timeout: 10000 });

        const titleText = await page.$eval('.page-header h1', el => el.textContent.trim());
        const kpiTotal = await page.$eval('#kpiTotal', el => el.textContent.trim());
        console.log(`   ✓ Page title: "${titleText}", KPI Total: "${kpiTotal}"`);
        if (!titleText.includes('Індекс різноманіття') || !kpiTotal.includes('4')) {
            throw new Error(`Unexpected page header or total: title=${titleText}, total=${kpiTotal}`);
        }
        passedTests++; // Metric 1

        console.log('=== TEST 2: KPI Grid Content ===');
        const kpiCats = await page.$eval('#kpiCategories', el => el.textContent.trim());
        const kpiStock = await page.$eval('#kpiStock', el => el.textContent.trim());
        const kpiWithStock = await page.$eval('#kpiWithStock', el => el.textContent.trim());
        console.log(`   ✓ KPI Categories: "${kpiCats}", Stock: "${kpiStock}", With Stock: "${kpiWithStock}"`);
        if (!kpiStock.includes('т') || !kpiCats.includes('/')) {
            throw new Error(`KPI formatting failed: cats=${kpiCats}, stock=${kpiStock}`);
        }
        passedTests++; // Metric 2

        console.log('=== TEST 3: Category Filtering (Round & Square) ===');
        // Click "Круглі"
        await page.click('.filter-btn[data-cat="round"]');
        await page.waitForFunction(() => {
            const count = document.getElementById('totalCount');
            return count && count.textContent.replace(/\s+/g, '') === '1841';
        }, { timeout: 10000 });
        const roundCount = await page.$eval('#totalCount', el => el.textContent.trim());
        console.log(`   ✓ Round filter total count: ${roundCount}`);

        // Click "Квадратні"
        await page.click('.filter-btn[data-cat="square_prof"]');
        await page.waitForFunction(() => {
            const count = document.getElementById('totalCount');
            return count && count.textContent.replace(/\s+/g, '') === '141';
        }, { timeout: 10000 });
        const sqCount = await page.$eval('#totalCount', el => el.textContent.trim());
        console.log(`   ✓ Square filter total count: ${sqCount}`);

        // Click "Всі"
        await page.click('.filter-btn[data-cat=""]');
        await page.waitForFunction(() => {
            const count = document.getElementById('totalCount');
            return count && count.textContent.replace(/\s+/g, '') === '4450';
        }, { timeout: 10000 });
        console.log(`   ✓ Reset to "Всі": total count 4 450`);
        passedTests++; // Metric 3

        console.log('=== TEST 4: Search & Table Rendering ===');
        await page.type('#searchInput', '140х10');
        await page.waitForFunction(() => {
            const tbody = document.getElementById('productsBody');
            return tbody && tbody.innerText.includes('140х10');
        }, { timeout: 10000 });
        const rowCount = await page.$$eval('#productsBody tr', rows => rows.length);
        console.log(`   ✓ Search for "140х10" returned ${rowCount} rows`);
        if (rowCount === 0) throw new Error('Search returned 0 rows for 140х10');

        // Clear search
        await page.evaluate(() => {
            const inp = document.getElementById('searchInput');
            inp.value = '';
            inp.dispatchEvent(new Event('input'));
        });
        await page.waitForFunction(() => {
            const count = document.getElementById('totalCount');
            return count && count.textContent.replace(/\s+/g, '') === '4450';
        }, { timeout: 10000 });
        passedTests++; // Metric 4

        console.log('=== TEST 5: Interactive Pagination ===');
        const firstPageCode = await page.$eval('#productsBody tr:first-child code', el => el.textContent.trim());
        await page.click('#nextPage');
        await new Promise(r => setTimeout(r, 600));
        const secondPageInfo = await page.$eval('#pageInfo', el => el.textContent.trim());
        const secondPageCode = await page.$eval('#productsBody tr:first-child code', el => el.textContent.trim());
        console.log(`   ✓ Page 2 info: "${secondPageInfo}", first row code: "${secondPageCode}"`);
        if (!secondPageInfo.startsWith('2 /') || secondPageCode === firstPageCode) {
            throw new Error(`Pagination failed: info=${secondPageInfo}, code=${secondPageCode}`);
        }
        await page.click('#prevPage');
        await new Promise(r => setTimeout(r, 600));
        const backPageInfo = await page.$eval('#pageInfo', el => el.textContent.trim());
        if (!backPageInfo.startsWith('1 /')) {
            throw new Error(`Pagination back failed: info=${backPageInfo}`);
        }
        console.log(`   ✓ Navigated back to page 1`);
        passedTests++; // Metric 5

        console.log('=== TEST 6: Sidebar link in index.html ===');
        await page.goto('http://localhost:5000/?token=utsk2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });
        await page.waitForSelector('.sidebar');
        const sidebarLink = await page.$eval('a[href*="/diversity-index"]', el => ({
            text: el.textContent.trim(),
            href: el.getAttribute('href')
        }));
        console.log(`   ✓ Sidebar link found: text="${sidebarLink.text}", href="${sidebarLink.href}"`);
        if (!sidebarLink.text.includes('Індекс різноманіття') || !sidebarLink.href.includes('/diversity-index')) {
            throw new Error(`Invalid sidebar link: ${JSON.stringify(sidebarLink)}`);
        }
        passedTests++; // Metric 6

        console.log('=== TEST 7: Link from /product-analytics (without code) ===');
        await page.goto('http://localhost:5000/product-analytics?token=utsk2026&code=4501&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 20000
        });
        await page.waitForSelector('#btn-diversity-matrix');
        const diversityBtn = await page.$eval('#btn-diversity-matrix', el => ({
            title: el.getAttribute('title'),
            href: el.getAttribute('href')
        }));
        console.log(`   ✓ product-analytics diversity btn: href="${diversityBtn.href}", title="${diversityBtn.title}"`);
        if (!diversityBtn.href.includes('/diversity-index') || diversityBtn.href.includes('code=')) {
            throw new Error(`product-analytics link invalid or still contains code: ${diversityBtn.href}`);
        }
        if (!diversityBtn.title.includes('каталогу')) {
            throw new Error(`product-analytics title not updated: ${diversityBtn.title}`);
        }

        // Test navigation by clicking
        await Promise.all([
            page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 15000 }),
            page.click('#btn-diversity-matrix')
        ]);
        const finalUrl = page.url();
        console.log(`   ✓ Successfully navigated from product-analytics to: ${finalUrl}`);
        if (!finalUrl.includes('/diversity-index')) {
            throw new Error(`Navigation failed: ${finalUrl}`);
        }
        passedTests++; // Metric 7

        // Capture Screenshots
        console.log('=== CAPTURING SCREENSHOTS ===');
        const screenshotsDir = path.join(__dirname, 'reports', 'screenshots');
        if (!fs.existsSync(screenshotsDir)) {
            fs.mkdirSync(screenshotsDir, { recursive: true });
        }

        // 1. Full page
        await page.goto('http://localhost:5000/diversity-index?token=utsk2026&year=2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });
        await page.waitForFunction(() => document.getElementById('kpiTotal')?.textContent.trim() !== '—');
        const fullPath = path.join(screenshotsDir, 'diversity_index_full.png');
        await page.screenshot({ path: fullPath, fullPage: true });
        console.log(`   ✓ Saved full screenshot: ${fullPath}`);

        // 2. Filtered state
        await page.click('.filter-btn[data-cat="square_prof"]');
        await page.waitForFunction(() => document.getElementById('totalCount')?.textContent.trim() === '141');
        const filterPath = path.join(screenshotsDir, 'diversity_index_filtered.png');
        await page.screenshot({ path: filterPath });
        console.log(`   ✓ Saved filtered screenshot: ${filterPath}`);

        // 3. Sidebar in index.html
        await page.goto('http://localhost:5000/?token=utsk2026', {
            waitUntil: 'networkidle2',
            timeout: 15000
        });
        await page.waitForSelector('.sidebar');
        const sidebarEl = await page.$('.sidebar');
        const sidebarPath = path.join(screenshotsDir, 'diversity_index_sidebar.png');
        if (sidebarEl) {
            await sidebarEl.screenshot({ path: sidebarPath });
            console.log(`   ✓ Saved sidebar screenshot: ${sidebarPath}`);
        }

        // Copy to artifact directory
        const artifactDir = '/home/serg/.gemini/antigravity-cli/brain/66522b3e-08da-482f-8cd0-45d04ef6ffb0';
        if (fs.existsSync(artifactDir)) {
            fs.copyFileSync(fullPath, path.join(artifactDir, 'diversity_index_full.png'));
            fs.copyFileSync(filterPath, path.join(artifactDir, 'diversity_index_filtered.png'));
            if (fs.existsSync(sidebarPath)) {
                fs.copyFileSync(sidebarPath, path.join(artifactDir, 'diversity_index_sidebar.png'));
            }
            console.log(`   ✓ Screenshots copied to artifact dir: ${artifactDir}`);
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
