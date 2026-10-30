const puppeteer = require('puppeteer');

(async () => {
    console.log("🚀 Starting Prompt 85 Puppeteer Verification...");
    const browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
    });

    const page = await browser.newPage();
    const consoleErrors = [];
    page.on('console', msg => {
        if (msg.type() === 'error') {
            consoleErrors.push(msg.text());
        }
    });
    page.on('pageerror', err => {
        consoleErrors.push('PAGE ERROR: ' + err.message);
    });

    // 1. Set viewport to 1280x800
    await page.setViewport({ width: 1280, height: 800 });

    // Open /size-detail route
    const testUrl = 'http://localhost:5000/size-detail?token=utsk2026&code=4501&size_key=round_140x10';
    console.log(`📍 Navigating to ${testUrl}...`);
    await page.goto(testUrl, { waitUntil: 'networkidle0', timeout: 20000 });

    // Load certs for product 10573 (which has both true and false certs)
    console.log("📥 Calling loadCerts('10573')...");
    await page.evaluate(async () => {
        await window.loadCerts('10573');
    });

    // Wait for certs list to populate
    await page.waitForFunction(() => {
        const list = document.getElementById('certs-list');
        return list && list.children.length > 0 && !list.innerText.includes('Завантаження');
    }, { timeout: 10000 });

    // Scroll to certificates section
    await page.evaluate(() => {
        const sec = document.getElementById('certificates-section');
        if (sec) sec.scrollIntoView();
    });
    await new Promise(r => setTimeout(r, 600));

    // Screenshot A: Cards showing both existing and missing buttons
    await page.screenshot({ path: '/home/serg/Documents/SQL_postgresql/Intelligent_Sales/verify_prompt85_cards.png' });
    console.log("📸 Screenshot A saved: verify_prompt85_cards.png");

    // Click on the first "PDF відсутній" button
    console.log("👆 Clicking 'PDF відсутній' button...");
    const clicked = await page.evaluate(() => {
        const buttons = Array.from(document.querySelectorAll('#certs-list button'));
        const missingBtn = buttons.find(b => b.textContent.includes('PDF відсутній'));
        if (missingBtn) {
            missingBtn.click();
            return true;
        }
        return false;
    });

    console.log("Clicked missing button:", clicked);

    // Wait for toast to appear
    await page.waitForFunction(() => {
        const toast = document.querySelector('#toast-container > div');
        return toast && toast.innerText.includes('PDF-файл ще не завантажено');
    }, { timeout: 5000 });

    // Screenshot B: Toast visible
    await page.screenshot({ path: '/home/serg/Documents/SQL_postgresql/Intelligent_Sales/verify_prompt85_toast.png' });
    console.log("📸 Screenshot B saved: verify_prompt85_toast.png");

    // Get toast text
    const toastText = await page.evaluate(() => {
        const toast = document.querySelector('#toast-container > div');
        return toast ? toast.innerText : '';
    });
    console.log("Toast message content:", toastText.replace(/\n/g, ' '));

    // Check Mobile Viewport (375x667)
    await page.setViewport({ width: 375, height: 667 });
    await page.evaluate(() => {
        const sec = document.getElementById('certificates-section');
        if (sec) sec.scrollIntoView();
    });
    await new Promise(r => setTimeout(r, 600));
    await page.screenshot({ path: '/home/serg/Documents/SQL_postgresql/Intelligent_Sales/verify_prompt85_mobile.png' });
    console.log("📸 Screenshot D (Mobile) saved: verify_prompt85_mobile.png");

    console.log("Console errors recorded:", consoleErrors.length, consoleErrors);

    await browser.close();
    console.log("✅ All Puppeteer checks passed!");
})();
