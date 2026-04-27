#!/bin/bash
cd /home/serg/Documents/SQL_postgresql/Intelligent_Sales/utsk_web
source venv/bin/activate
echo "🚀 Запуск UTSK Web Server..."
echo "📍 Локально: http://localhost:5000/?token=utsk2026"
python backend/app.py
