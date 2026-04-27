#!/bin/bash

# =============================================================================
# СКРИПТ РЕЗЕРВНОГО КОПИРОВАНИЯ БАЗЫ ДАННЫХ UTSK
# =============================================================================

# --- НАСТРОЙКИ ---
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="bd_intelligent_sales"
DB_USER="postgres"
export PGPASSWORD="root"  # ← Ваш пароль

# Папка для бекапов
BACKUP_DIR="/home/serg/Documents/SQL_postgresql/Intelligent_Sales/SQL"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/backup_${DB_NAME}_${TIMESTAMP}.sql"

# Цвета
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "🚀 Создание резервной копии базы данных..."
echo "    База данных: $DB_NAME"
echo "    Папка: $BACKUP_DIR"

mkdir -p "$BACKUP_DIR"

# Создание дампа
pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -F c -b -v -f "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Резервная копия создана: $BACKUP_FILE${NC}"
else
    echo -e "${RED}❌ Ошибка при создании резервной копии${NC}"
    exit 1
fi
