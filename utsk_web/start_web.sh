#!/bin/bash
cd /home/serg/Documents/SQL_postgresql/Intelligent_Sales/utsk_web

# --- Освободить порт 5000 если занят ---
EXISTING=$(lsof -ti:5000 2>/dev/null)
if [ -n "$EXISTING" ]; then
    echo "⚠️  Порт 5000 занят (PID $EXISTING) — останавливаем..."
    kill -9 $EXISTING
    sleep 1
    echo "✅ Старый процесс завершён"
fi

source venv/bin/activate
echo "🚀 Запуск UTSK Web Server..."
echo "📍 Локально: http://localhost:5000/?token=utsk2026"
python backend/app.py
