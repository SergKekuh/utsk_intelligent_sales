#!/bin/bash

# =============================================================================
# СКРИПТ СОЗДАНИЯ СТРУКТУРЫ ПРОЕКТА UTSK INTELLIGENT SALES C++ (ЧАСТЬ 1)
# =============================================================================
# Автор: UTSK Team
# Дата: 22.04.2026
# Описание: Создаёт полную структуру папок и пустых файлов для C++ проекта
# =============================================================================

set -e  # Остановка при любой ошибке

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Путь к проекту
PROJECT_ROOT="/home/serg/Documents/SQL_postgresql/Intelligent_Sales/utsk_intelligent_sales"

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}     СОЗДАНИЕ СТРУКТУРЫ ПРОЕКТА UTSK INTELLIGENT SALES C++${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo ""
echo -e "${CYAN}📁 Путь проекта:${NC} ${PROJECT_ROOT}"
echo ""

# Проверка существования директории
if [ -d "$PROJECT_ROOT" ]; then
    echo -e "${YELLOW}⚠️  Директория уже существует: ${PROJECT_ROOT}${NC}"
    read -p "Перезаписать структуру? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Операция отменена.${NC}"
        exit 1
    fi
    echo -e "${YELLOW}🗑️  Удаление существующей директории...${NC}"
    rm -rf "$PROJECT_ROOT"
fi

echo -e "${GREEN}📁 Создание корневой директории...${NC}"
mkdir -p "$PROJECT_ROOT"

# Переход в директорию проекта
cd "$PROJECT_ROOT"

echo -e "${GREEN}📁 Создание структуры каталогов...${NC}"

# -----------------------------------------------------------------------------
# СОЗДАНИЕ ПАПОК
# -----------------------------------------------------------------------------
mkdir -p config
mkdir -p include/core
mkdir -p include/models
mkdir -p include/services
mkdir -p include/ui
mkdir -p src/core
mkdir -p src/models
mkdir -p src/services
mkdir -p src/ui
mkdir -p tests/unit
mkdir -p tests/integration
mkdir -p tests/mocks
mkdir -p tests/fixtures
mkdir -p libs
mkdir -p resources/icons
mkdir -p resources/forms
mkdir -p docs/doxygen
mkdir -p docker
mkdir -p .github/workflows
mkdir -p cmake

echo -e "${GREEN}📄 Создание пустых файлов...${NC}"

# -----------------------------------------------------------------------------
# КОРНЕВЫЕ ФАЙЛЫ
# -----------------------------------------------------------------------------
touch README.md
touch .gitignore
touch CMakeLists.txt
touch CMakePresets.json
touch LICENSE

# -----------------------------------------------------------------------------
# CONFIG
# -----------------------------------------------------------------------------
touch config/db_config.json
touch config/db_config.example.json

# -----------------------------------------------------------------------------
# INCLUDE/CORE
# -----------------------------------------------------------------------------
touch include/core/Database.hpp
touch include/core/Config.hpp
touch include/core/Logger.hpp

# -----------------------------------------------------------------------------
# INCLUDE/MODELS
# -----------------------------------------------------------------------------
touch include/models/Client.hpp
touch include/models/Product.hpp
touch include/models/Document.hpp
touch include/models/SaleLine.hpp
touch include/models/StatusRule.hpp
touch include/models/ActivityDirection.hpp
touch include/models/Recommendation.hpp

# -----------------------------------------------------------------------------
# INCLUDE/SERVICES
# -----------------------------------------------------------------------------
touch include/services/ClientService.hpp
touch include/services/ProductService.hpp
touch include/services/DocumentService.hpp
touch include/services/AnalyticsService.hpp
touch include/services/RecommendationService.hpp

# -----------------------------------------------------------------------------
# INCLUDE/UI
# -----------------------------------------------------------------------------
touch include/ui/ConsoleUI.hpp
touch include/ui/ConsoleMenu.hpp
touch include/ui/TablePrinter.hpp
touch include/ui/MainWindow.hpp
touch include/ui/ClientDialog.hpp
touch include/ui/DashboardWidget.hpp
touch include/ui/RecommendationsWidget.hpp
touch include/ui/ChartsWidget.hpp

# -----------------------------------------------------------------------------
# SRC/CORE
# -----------------------------------------------------------------------------
touch src/core/Database.cpp
touch src/core/Config.cpp
touch src/core/Logger.cpp

# -----------------------------------------------------------------------------
# SRC/MODELS
# -----------------------------------------------------------------------------
touch src/models/Client.cpp
touch src/models/Product.cpp
touch src/models/Document.cpp
touch src/models/SaleLine.cpp
touch src/models/StatusRule.cpp
touch src/models/ActivityDirection.cpp
touch src/models/Recommendation.cpp

# -----------------------------------------------------------------------------
# SRC/SERVICES
# -----------------------------------------------------------------------------
touch src/services/ClientService.cpp
touch src/services/ProductService.cpp
touch src/services/DocumentService.cpp
touch src/services/AnalyticsService.cpp
touch src/services/RecommendationService.cpp

# -----------------------------------------------------------------------------
# SRC/UI
# -----------------------------------------------------------------------------
touch src/ui/ConsoleUI.cpp
touch src/ui/ConsoleMenu.cpp
touch src/ui/TablePrinter.cpp
touch src/ui/MainWindow.cpp
touch src/ui/ClientDialog.cpp
touch src/ui/DashboardWidget.cpp
touch src/ui/RecommendationsWidget.cpp
touch src/ui/ChartsWidget.cpp

# -----------------------------------------------------------------------------
# MAIN ФАЙЛЫ
# -----------------------------------------------------------------------------
touch src/main_console.cpp
touch src/main_gui.cpp

# -----------------------------------------------------------------------------
# TESTS
# -----------------------------------------------------------------------------
touch tests/CMakeLists.txt
touch tests/unit/test_database.cpp
touch tests/unit/test_config.cpp
touch tests/unit/test_client_model.cpp
touch tests/unit/test_client_service.cpp
touch tests/unit/test_analytics_service.cpp
touch tests/integration/test_database_integration.cpp
touch tests/integration/test_recommendations_integration.cpp
touch tests/integration/test_full_workflow.cpp
touch tests/mocks/mock_database.hpp
touch tests/fixtures/test_data.sql
touch tests/fixtures/test_config.json

# -----------------------------------------------------------------------------
# RESOURCES
# -----------------------------------------------------------------------------
touch resources/styles.qss
touch resources/forms/mainwindow.ui
touch resources/forms/clientdialog.ui
touch resources/forms/dashboard.ui

# -----------------------------------------------------------------------------
# DOCS
# -----------------------------------------------------------------------------
touch docs/README.md
touch docs/INSTALL.md
touch docs/USER_GUIDE.md
touch docs/DEVELOPER_GUIDE.md
touch docs/API_REFERENCE.md
touch docs/DATABASE_REFERENCE.md
touch docs/DEPLOYMENT.md
touch docs/CHANGELOG.md
touch docs/doxygen/Doxyfile

# -----------------------------------------------------------------------------
# DOCKER
# -----------------------------------------------------------------------------
touch docker/Dockerfile
touch docker/docker-compose.yml
touch docker/init.sql
touch docker/.env.example

# -----------------------------------------------------------------------------
# GITHUB ACTIONS
# -----------------------------------------------------------------------------
touch .github/workflows/build.yml
touch .github/workflows/release.yml
touch .github/workflows/deploy.yml

# -----------------------------------------------------------------------------
# CMAKE ДОПОЛНИТЕЛЬНЫЕ ФАЙЛЫ
# -----------------------------------------------------------------------------
touch cmake/CompilerOptions.cmake
touch cmake/FindPQXX.cmake

echo -e "${GREEN}📝 Заполнение файлов начальным содержимым...${NC}"

# -----------------------------------------------------------------------------
# ЗАПОЛНЕНИЕ .gitignore
# -----------------------------------------------------------------------------
cat > .gitignore << 'GITIGNORE_EOF'
# Сборка
build/
cmake-build-*/
out/
*.o
*.obj
*.a
*.so
*.dylib
*.dll

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
*.user
*.kdev4

# Бинарники
*.exe
*.out
*.app
utsk_console
utsk_gui
utsk_intelligent_sales

# Конфиги с паролями
config/db_config.json
*.secret
*.private
.env

# Логи
*.log
logs/

# Системные файлы
.DS_Store
Thumbs.db
desktop.ini

# Qt
moc_*.cpp
moc_*.h
ui_*.h
qrc_*.cpp
*.qm
Makefile
*.pro.user
*.pro.user.*

# Doxygen
docs/generated/

# Docker
docker/.env
GITIGNORE_EOF

# -----------------------------------------------------------------------------
# ЗАПОЛНЕНИЕ README.md (упрощённая версия без конфликтующих символов)
# -----------------------------------------------------------------------------
cat > README.md << 'README_EOF'
# UTSK Intelligent Sales - C++ Application

Version: 1.0.0
Language: C++17
License: Proprietary

## Description

UTSK Intelligent Sales is a console and GUI application for working with 
the bd_intelligent_sales PostgreSQL database.

Features:
- RFM analytics - automatic client segmentation
- Activity direction detection - revenue-based voting
- Smart recommendations - personalized product suggestions
- ML self-learning - product scoring based on manager actions
- Dashboards - KPI and client status visualization

## Quick Start

### Clone repository
git clone https://github.com/your-username/utsk_intelligent_sales.git
cd utsk_intelligent_sales

### Install dependencies (Ubuntu/Debian)
sudo apt update
sudo apt install -y cmake g++ make libpqxx-dev nlohmann-json3-dev

### Configure database
cp config/db_config.example.json config/db_config.json
nano config/db_config.json

### Build (AFTER implementing main_console.cpp)
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel $(nproc)

### Run console version
./build/utsk_console

## Project Structure

utsk_intelligent_sales/
├── config/          # Configuration files
├── include/         # Header files (.hpp)
├── src/             # Source files (.cpp)
├── tests/           # Unit and integration tests
├── resources/       # Icons, styles, UI forms
├── docs/            # Documentation
├── docker/          # Docker containerization
├── .github/         # GitHub Actions CI/CD
└── cmake/           # CMake modules

## Dependencies

| Library | Purpose | Version |
|---------|---------|---------|
| C++ | Programming language | 17+ |
| libpqxx | PostgreSQL connector | 7.x |
| nlohmann_json | JSON parsing | 3.x |
| Qt6 (opt.) | GUI interface | 6.4+ |
| Google Test (opt.) | Testing | 1.12+ |

## License

Proprietary. All rights reserved. Copyright UTSK, 2026.
README_EOF

# -----------------------------------------------------------------------------
# ЗАПОЛНЕНИЕ db_config.example.json
# -----------------------------------------------------------------------------
cat > config/db_config.example.json << 'CONFIG_EOF'
{
    "database": {
        "host": "localhost",
        "port": 5432,
        "dbname": "bd_intelligent_sales",
        "user": "postgres",
        "password": "your_password_here"
    },
    "app": {
        "log_level": "info",
        "log_file": "utsk.log"
    }
}
CONFIG_EOF

# -----------------------------------------------------------------------------
# ЗАПОЛНЕНИЕ CMakeLists.txt
# -----------------------------------------------------------------------------
cat > CMakeLists.txt << 'CMAKE_EOF'
cmake_minimum_required(VERSION 3.16)
project(UTSK_Intelligent_Sales VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(BUILD_TESTS "Build unit tests" OFF)
option(BUILD_GUI "Build Qt GUI version" OFF)

find_package(nlohmann_json REQUIRED)
find_package(libpqxx REQUIRED)

add_executable(utsk_console
    src/main_console.cpp
    src/core/Database.cpp
    src/core/Config.cpp
    src/core/Logger.cpp
    src/models/Client.cpp
    src/models/Product.cpp
    src/models/Document.cpp
    src/models/SaleLine.cpp
    src/services/ClientService.cpp
    src/services/ProductService.cpp
    src/services/AnalyticsService.cpp
    src/ui/ConsoleUI.cpp
    src/ui/ConsoleMenu.cpp
    src/ui/TablePrinter.cpp
)

target_include_directories(utsk_console PRIVATE include)
target_link_libraries(utsk_console pqxx nlohmann_json::nlohmann_json)

if(BUILD_GUI)
    find_package(Qt6 REQUIRED COMPONENTS Core Widgets Sql Charts)
    qt_standard_project_setup()
    
    add_executable(utsk_gui
        src/main_gui.cpp
        src/core/Database.cpp
        src/core/Config.cpp
        src/core/Logger.cpp
        src/models/Client.cpp
        src/models/Product.cpp
        src/services/ClientService.cpp
        src/services/RecommendationService.cpp
        src/ui/MainWindow.cpp
        src/ui/ClientDialog.cpp
        src/ui/DashboardWidget.cpp
        src/ui/RecommendationsWidget.cpp
        src/ui/ChartsWidget.cpp
    )
    
    target_include_directories(utsk_gui PRIVATE include)
    target_link_libraries(utsk_gui Qt6::Core Qt6::Widgets Qt6::Sql Qt6::Charts pqxx nlohmann_json::nlohmann_json)
endif()

if(BUILD_TESTS)
    find_package(GTest REQUIRED)
    enable_testing()
    add_subdirectory(tests)
endif()

message(STATUS "UTSK Intelligent Sales v1.0.0")
CMAKE_EOF

# -----------------------------------------------------------------------------
# ЗАПОЛНЕНИЕ docker-compose.yml
# -----------------------------------------------------------------------------
cat > docker/docker-compose.yml << 'DOCKER_EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: utsk_db
    environment:
      POSTGRES_DB: bd_intelligent_sales
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${DB_PASSWORD:-root}
    ports:
      - "5432:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    build: .
    container_name: utsk_app
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      UTSK_DB_HOST: postgres
      UTSK_DB_PORT: 5432
      UTSK_DB_NAME: bd_intelligent_sales
      UTSK_DB_USER: postgres
      UTSK_DB_PASSWORD: ${DB_PASSWORD:-root}
    stdin_open: true
    tty: true

  pgadmin:
    image: dpage/pgadmin4
    container_name: utsk_pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: ${PGADMIN_EMAIL:-admin@utsk.ua}
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD:-admin}
    ports:
      - "8080:80"
    depends_on:
      - postgres
    volumes:
      - pgadmin_data:/var/lib/pgadmin

volumes:
  pg_data:
  pgadmin_data:
DOCKER_EOF

# -----------------------------------------------------------------------------
# ЗАПОЛНЕНИЕ .env.example
# -----------------------------------------------------------------------------
cat > docker/.env.example << 'ENV_EOF'
# PostgreSQL
DB_PASSWORD=root

# pgAdmin
PGADMIN_EMAIL=admin@utsk.ua
PGADMIN_PASSWORD=admin
ENV_EOF

# -----------------------------------------------------------------------------
# ЗАПОЛНЕНИЕ CHANGELOG.md
# -----------------------------------------------------------------------------
cat > docs/CHANGELOG.md << 'CHANGELOG_EOF'
# Changelog

All notable changes to UTSK Intelligent Sales will be documented in this file.

## [Unreleased]

### Added
- Initial project structure
- Basic CMake configuration
- Docker and docker-compose support
- Test templates

## [1.0.0] - 2026-04-22

### Added
- First release
- Project directory structure
- Basic configuration files
CHANGELOG_EOF

# -----------------------------------------------------------------------------
# ПОДСЧЁТ СТАТИСТИКИ
# -----------------------------------------------------------------------------
TOTAL_DIRS=$(find . -type d -not -path "./.git*" 2>/dev/null | wc -l)
TOTAL_FILES=$(find . -type f -not -path "./.git*" 2>/dev/null | wc -l)

echo ""
echo -e "${GREEN}======================================================================${NC}"
echo -e "${GREEN}                    ✅ СТРУКТУРА СОЗДАНА УСПЕШНО!${NC}"
echo -e "${GREEN}======================================================================${NC}"
echo ""
echo -e "${CYAN}📊 Статистика:${NC}"
echo -e "   📁 Создано директорий: ${TOTAL_DIRS}"
echo -e "   📄 Создано файлов: ${TOTAL_FILES}"
echo -e "   📍 Путь: ${PROJECT_ROOT}"
echo ""
echo -e "${YELLOW}📋 СЛЕДУЮЩИЕ ШАГИ (выполнить последовательно):${NC}"
echo ""
echo -e "${CYAN}1. Перейти в директорию проекта:${NC}"
echo -e "   ${GREEN}cd ${PROJECT_ROOT}${NC}"
echo ""
echo -e "${CYAN}2. Инициализировать Git репозиторий:${NC}"
echo -e "   ${GREEN}git init${NC}"
echo -e "   ${GREEN}git add .${NC}"
echo -e "   ${GREEN}git commit -m \"Initial commit: UTSK Intelligent Sales project structure\"${NC}"
echo ""
echo -e "${CYAN}3. Создать репозиторий на GitHub (через веб-интерфейс) и привязать:${NC}"
echo -e "   ${GREEN}git remote add origin https://github.com/your-username/utsk_intelligent_sales.git${NC}"
echo -e "   ${GREEN}git branch -M main${NC}"
echo -e "   ${GREEN}git push -u origin main${NC}"
echo ""
echo -e "${CYAN}4. Создать конфиг с паролем к БД:${NC}"
echo -e "   ${GREEN}cp config/db_config.example.json config/db_config.json${NC}"
echo -e "   ${GREEN}nano config/db_config.json  # указать реальный пароль${NC}"
echo ""
echo -e "${YELLOW}⚠️  ВАЖНО:${NC}"
echo -e "   - Файлы .cpp сейчас ПУСТЫЕ. CMake НЕ соберёт проект."
echo -e "   - Это нормально! Мы будем заполнять их в следующих частях."
echo -e "   - ${GREEN}НЕ ЗАПУСКАЙТЕ cmake --build${NC} пока не реализован main_console.cpp"
echo ""
echo -e "${BLUE}📚 Что уже готово:${NC}"
echo -e "   ✅ README.md — описание проекта"
echo -e "   ✅ .gitignore — правила для Git"
echo -e "   ✅ CMakeLists.txt — конфигурация сборки"
echo -e "   ✅ db_config.example.json — шаблон конфига"
echo -e "   ✅ docker-compose.yml — для контейнеризации"
echo -e "   ✅ Структура всех .hpp и .cpp файлов (пустые)"
echo ""
echo -e "${BLUE}🚀 Что дальше:${NC}"
echo -e "   Когда выполните шаги 1-4, скажите:"
echo -e "   ${GREEN}\"Переходим к Части 2\"${NC} — и мы начнём заполнять файлы."
echo ""
echo -e "${GREEN}======================================================================${NC}"
