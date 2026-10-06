const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
        headless: 'new'
    });
    const page = await browser.newPage();
    
    const errors = [];
    page.on('console', msg => {
        if (msg.type() === 'error') {
            errors.push(msg.text());
        }
        console.log(`[BROWSER ${msg.type().toUpperCase()}]`, msg.text());
    });
    page.on('pageerror', err => {
        errors.push(err.toString());
        console.error('[BROWSER PAGEERROR]', err.toString());
    });

    await page.setViewport({ width: 1440, height: 1000 });

    console.log('1. Navigating to client-detail...');
    await page.goto('http://localhost:5000/client-detail?token=utsk2026&code=4501&year=2026', {
        waitUntil: 'networkidle2'
    });

    // Wait for recommendation items to load
    await page.waitForSelector('.rec-item', { timeout: 10000 });
    console.log('✓ Recommendations loaded on client-detail');

    // Scroll to recommendations block and screenshot
    const recBlock = await page.$('#rec-block');
    if (recBlock) {
        await recBlock.scrollIntoView();
        await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_client_rec_card.png' });
        console.log('✓ Saved screenshot_client_rec_card.png');
    }

    // Get href of first rec-item
    const firstRecHref = await page.$eval('.rec-item', el => el.getAttribute('href'));
    console.log('First recommendation href:', firstRecHref);

    // Click first recommendation item
    console.log('2. Clicking first recommendation item...');
    await Promise.all([
        page.waitForNavigation({ waitUntil: 'networkidle2' }),
        page.click('.rec-item')
    ]);

    const currentUrl = page.url();
    console.log('Current URL after navigation:', currentUrl);

    // Wait for recommendation detail page to finish loading
    await page.waitForSelector('#size-title', { timeout: 10000 });
    await page.waitForFunction(() => {
        const title = document.getElementById('size-title')?.textContent;
        return title && !title.includes('Завантаження');
    }, { timeout: 10000 });

    console.log('✓ Recommendation detail page loaded successfully');

    // Screenshot Tab 1: Overview
    await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_rec_tab1_overview.png', fullPage: false });
    console.log('✓ Saved screenshot_rec_tab1_overview.png');

    // Tab 2: Monthly
    console.log('3. Switching to Tab 2 (Динаміка)...');
    await page.evaluate(() => {
        const btn = Array.from(document.querySelectorAll('.tab-btn')).find(b => b.textContent.includes('Динаміка'));
        if (btn) btn.click();
    });
    await new Promise(r => setTimeout(r, 600));
    await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_rec_tab2_monthly.png', fullPage: false });
    console.log('✓ Saved screenshot_rec_tab2_monthly.png');

    // Tab 3: Segment
    console.log('4. Switching to Tab 3 (Порівняння з сегментом)...');
    await page.evaluate(() => {
        const btn = Array.from(document.querySelectorAll('.tab-btn')).find(b => b.textContent.includes('Порівняння'));
        if (btn) btn.click();
    });
    await new Promise(r => setTimeout(r, 600));
    await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_rec_tab3_segment.png', fullPage: false });
    console.log('✓ Saved screenshot_rec_tab3_segment.png');

    // Tab 4: Products
    console.log('5. Switching to Tab 4 (Товари за ГОСТ)...');
    await page.evaluate(() => {
        const btn = Array.from(document.querySelectorAll('.tab-btn')).find(b => b.textContent.includes('Товари'));
        if (btn) btn.click();
    });
    await new Promise(r => setTimeout(r, 600));
    await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_rec_tab4_products.png', fullPage: false });
    console.log('✓ Saved screenshot_rec_tab4_products.png');

    // Tab 5: Similar
    console.log('6. Switching to Tab 5 (Рекомендації)...');
    await page.evaluate(() => {
        const btn = Array.from(document.querySelectorAll('.tab-btn')).find(b => b.textContent.includes('Рекомендації'));
        if (btn) btn.click();
    });
    await new Promise(r => setTimeout(r, 600));
    await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_rec_tab5_similar.png', fullPage: false });
    console.log('✓ Saved screenshot_rec_tab5_similar.png');

    console.log('Total console/page errors:', errors.length);
    if (errors.length > 0) {
        console.error('Errors:', errors);
    }

    await browser.close();
    console.log('Verification finished.');
})();
