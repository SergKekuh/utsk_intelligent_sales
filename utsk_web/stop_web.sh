#!/bin/bash
echo "🛑 Остановка UTSK Web Server..."
pkill -f "backend/app.py" 2>/dev/null
fuser -k 5000/tcp 2>/dev/null
echo "✅ Сервер остановлен, порт 5000 свободен"
