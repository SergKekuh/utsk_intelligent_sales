const fs = require('fs');
const path = require('path');

const FRONTEND_DIR = '/home/serg/Documents/SQL_postgresql/Intelligent_Sales/utsk_web/frontend/static';

// 1. Fix client-detail.html (Name)
const clientDetailFile = path.join(FRONTEND_DIR, 'client-detail.html');
let clientContent = fs.readFileSync(clientDetailFile, 'utf8');
clientContent = clientContent.replace(
    /let metaParts = \[`Код клиента: \$\{c\.code\}`\];/,
    `document.getElementById('client-name').textContent = c.name;
                document.title = \`UTSK — \${c.name}\`;
                
                let metaParts = [\`Код клиента: \${c.code}\`];`
);
fs.writeFileSync(clientDetailFile, clientContent);

// 2. Replace "Счетов" with "Продаж"
const filesToReplace = [
    'index.html',
    'inactive-clients-analytics.html',
    'new-clients-analytics.html',
    'returned-clients-analytics.html'
];
filesToReplace.forEach(file => {
    const filePath = path.join(FRONTEND_DIR, file);
    if (!fs.existsSync(filePath)) return;
    let content = fs.readFileSync(filePath, 'utf8');
    
    // index.html
    if (file === 'index.html') {
        content = content.replace(/Счетов: \$\{c\.invoice_count/g, 'Продаж: ${c.invoice_count');
    }
    
    // others
    content = content.replace(/Счетов \(2025\)/g, 'Продаж (2025)');
    content = content.replace(/Счетов \(2024\)/g, 'Продаж (2024)');
    content = content.replace(/Выручка \/ Счетов/g, 'Выручка / Продажі');
    content = content.replace(/>Счетов</g, '>Продаж<');
    content = content.replace(/Товарных счетов в/g, 'Товарних продаж у');
    
    fs.writeFileSync(filePath, content);
});

// 3. Fix direction-detail.html Drilldown API call
const dirDetailFile = path.join(FRONTEND_DIR, 'direction-detail.html');
let dirContent = fs.readFileSync(dirDetailFile, 'utf8');
const oldUrlLogic = /let url = `\/api\/analytics\/direction\/size-drilldown\?token=\$\{TOKEN\}&direction_id=\$\{DIRECTION_ID\}&year=\$\{currentYear\}&diameter=\$\{diameter\}`;[\s\n]*if \(wall\) url \+= `&wall=\$\{wall\}`;/;
const newUrlLogic = `const sizeKey = wall ? \`round_\${diameter}x\${wall}\` : \`round_\${diameter}\`;
            let url = \`/api/analytics/directions/size-drilldown?token=\${TOKEN}&direction_id=\${DIRECTION_ID}&year=\${currentYear}&size_key=\${sizeKey}\`;`;
dirContent = dirContent.replace(oldUrlLogic, newUrlLogic);
fs.writeFileSync(dirDetailFile, dirContent);

console.log("Fixes applied successfully.");
