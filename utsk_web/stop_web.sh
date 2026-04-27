#!/bin/bash
echo "🛑 Остановка UTSK Web Server..."
pkill -f "python backend/app.py" 2>/dev/null && echo "✅ Сервер остановлен" || echo "⚠️ Сервер не был запущен"
