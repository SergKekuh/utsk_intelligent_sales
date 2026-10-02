const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({
        args: ['--no-sandbox', '--disable-setuid-sandbox'],
        headless: "new"
    });
    const page = await browser.newPage();
    
    // Catch console logs
    page.on('console', msg => console.log('PAGE LOG:', msg.text()));
    
    await page.setViewport({ width: 1440, height: 900 });
    
    await page.goto('http://localhost:5000/profile-pipes-analytics?token=utsk2026&code=4501&year=2026', {waitUntil: 'networkidle0'});
    await page.screenshot({path: 'profile_pipes_loaded.png'});
    
    console.log("Screenshot taken!");
    
    await browser.close();
})();
