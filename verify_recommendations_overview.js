const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--window-size=1400,900']
    });
    const page = await browser.newPage();
    await page.setViewport({ width: 1400, height: 900 });

    const errors = [];
    page.on('console', msg => {
        if (msg.type() === 'error') {
            errors.push({ page: page.url(), text: msg.text() });
        }
    });
    page.on('pageerror', err => errors.push({ page: page.url(), text: err.message }));

    console.log('1. Opening client-detail page...');
    await page.goto('http://localhost:5000/client-detail?token=utsk2026&code=4501', { waitUntil: 'networkidle2' });

    // Wait for recommendations to render
    await page.waitForSelector('#rec-block', { timeout: 10000 });
    await new Promise(r => setTimeout(r, 2000));

    // Screenshot of rec-block on client-detail
    const recBlock = await page.$('#rec-block');
    if (recBlock) {
        await recBlock.screenshot({ path: 'utsk_web/frontend/static/screenshot_rec_block_click.png' });
        console.log('Saved screenshot_rec_block_click.png');
    }

    // Verify rec-block data-href attribute
    const dataHref = await page.evaluate(() => {
        const el = document.getElementById('rec-block');
        return el ? el.dataset.href : null;
    });
    console.log('rec-block data-href:', dataHref);

    // Click on the rec-block header (h3) to navigate
    console.log('2. Clicking on rec-block header...');
    await Promise.all([
        page.waitForNavigation({ waitUntil: 'domcontentloaded' }),
        page.click('#rec-block h3')
    ]);
    console.log('Navigated to:', page.url());

    // Verify we are on recommendations-overview page
    if (!page.url().includes('recommendations-overview')) {
        console.error('FAILED: Expected recommendations-overview URL, got:', page.url());
    } else {
        console.log('SUCCESS: On recommendations-overview page!');
    }

    await new Promise(r => setTimeout(r, 2000));

    // Tab 1: Огляд
    console.log('3. Checking Tab 1 (Огляд)...');
    await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_rec_overview_tab1_overview.png' });
    console.log('Saved screenshot_rec_overview_tab1_overview.png');

    // Tab 2: Динаміка
    console.log('4. Switching to Tab 2 (Динаміка)...');
    await page.evaluate(() => {
        const btns = Array.from(document.querySelectorAll('.tab-btn'));
        const target = btns.find(b => b.innerText.includes('Динаміка'));
        if (target) target.click();
    });
    await new Promise(r => setTimeout(r, 1000));
    await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_rec_overview_tab2_monthly.png' });
    console.log('Saved screenshot_rec_overview_tab2_monthly.png');

    // Tab 3: ABC-аналіз
    console.log('5. Switching to Tab 3 (ABC-аналіз)...');
    await page.evaluate(() => {
        const btns = Array.from(document.querySelectorAll('.tab-btn'));
        const target = btns.find(b => b.innerText.includes('ABC'));
        if (target) target.click();
    });
    await new Promise(r => setTimeout(r, 1000));
    await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_rec_overview_tab3_abc.png' });
    console.log('Saved screenshot_rec_overview_tab3_abc.png');

    // Tab 4: Порівняння
    console.log('6. Switching to Tab 4 (Порівняння)...');
    await page.evaluate(() => {
        const btns = Array.from(document.querySelectorAll('.tab-btn'));
        const target = btns.find(b => b.innerText.includes('Порівняння'));
        if (target) target.click();
    });
    await new Promise(r => setTimeout(r, 1000));
    await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_rec_overview_tab4_compare.png' });
    console.log('Saved screenshot_rec_overview_tab4_compare.png');

    // Tab 5: Крос-сел
    console.log('7. Switching to Tab 5 (Крос-сел)...');
    await page.evaluate(() => {
        const btns = Array.from(document.querySelectorAll('.tab-btn'));
        const target = btns.find(b => b.innerText.includes('Крос-сел'));
        if (target) target.click();
    });
    await new Promise(r => setTimeout(r, 1000));
    await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_rec_overview_tab5_crosssell.png' });
    console.log('Saved screenshot_rec_overview_tab5_crosssell.png');

    // Test back button
    console.log('8. Testing back button...');
    const backHref = await page.evaluate(() => document.getElementById('back-link').href);
    console.log('Back button href:', backHref);

    // Also check cross-sell with client 2692 where pairs exist
    console.log('9. Checking recommendations-overview for client 2692 (crosssell pairs)...');
    await page.goto('http://localhost:5000/recommendations-overview?token=utsk2026&code=2692&year=2026', { waitUntil: 'networkidle2' });
    await new Promise(r => setTimeout(r, 2000));
    await page.evaluate(() => {
        const btns = Array.from(document.querySelectorAll('.tab-btn'));
        const target = btns.find(b => b.innerText.includes('Крос-сел'));
        if (target) target.click();
    });
    await new Promise(r => setTimeout(r, 1000));
    await page.screenshot({ path: 'utsk_web/frontend/static/screenshot_rec_overview_tab5_crosssell_2692.png' });
    console.log('Saved screenshot_rec_overview_tab5_crosssell_2692.png');

    console.log('Console errors encountered:', errors.length);
    if (errors.length > 0) {
        console.log('Errors:', errors);
    }

    await browser.close();
    console.log('All puppeteer checks finished.');
})();
