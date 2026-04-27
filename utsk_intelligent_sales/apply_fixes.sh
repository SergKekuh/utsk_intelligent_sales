#!/bin/bash

echo "🚀 Применяем исправления для UI и сервиса рекомендаций..."

echo "📄 Обновление include/ui/ConsoleUI.hpp..."
cat > include/ui/ConsoleUI.hpp << 'EOF'
#ifndef CONSOLE_UI_HPP
#define CONSOLE_UI_HPP

#include "core/Database.hpp"
#include "services/ClientService.hpp"
#include "services/ProductService.hpp"
#include "services/RecommendationService.hpp"
#include "ui/ConsoleMenu.hpp"
#include "ui/TablePrinter.hpp"

namespace utsk {

class ConsoleUI {
public:
    ConsoleUI(Database& db, ClientService& clientSvc, ProductService& productSvc, RecommendationService& recSvc);
    void run();

private:
    void showDashboard();
    void showProducts();
    void showStatusDistribution();
    void showDirectionDistribution();
    void showRequiringSurvey();
    void showClientList();
    void showRecommendations(const std::string& clientCode);
    void waitForKey();

    Database& m_db;
    ClientService& m_clientService;
    ProductService& m_productService;
    RecommendationService& m_recService;
    ConsoleMenu m_menu;
};

} // namespace utsk

#endif
EOF

echo "📄 Обновление src/ui/ConsoleUI.cpp..."
cat > src/ui/ConsoleUI.cpp << 'EOF'
#include "ui/ConsoleUI.hpp"
#include "core/Logger.hpp"
#include <iostream>
#include <iomanip>
#include <sstream>

namespace utsk {

ConsoleUI::ConsoleUI(Database& db, ClientService& clientSvc, ProductService& productSvc, RecommendationService& recSvc)
    : m_db(db), m_clientService(clientSvc), m_productService(productSvc), m_recService(recSvc) {
    
    m_menu.setTitle("UTSK INTELLIGENT SALES v1.0.0");
    
    m_menu.addItem("1", "📊 Дашборд", [this]() { showDashboard(); });
    m_menu.addItem("2", "👥 Клиенты (требуют опроса)", [this]() { showRequiringSurvey(); });
    m_menu.addItem("3", "🏷️  Статусы клиентов", [this]() { showStatusDistribution(); });
    m_menu.addItem("4", "🎯 Направления деятельности", [this]() { showDirectionDistribution(); });
    m_menu.addItem("5", "📦 Товары", [this]() { showProducts(); });
    m_menu.addItem("6", "💡 Рекомендации для клиента", [this]() { showClientList(); });
    m_menu.addSeparator();
    m_menu.addItem("0", "🚪 Выход", [this]() { m_menu.exit(); });
}

void ConsoleUI::run() { m_menu.run(); }

void ConsoleUI::waitForKey() {
    std::cout << "\nНажмите Enter для продолжения...";
    std::string dummy;
    std::getline(std::cin, dummy);
}

void ConsoleUI::showDashboard() {
    auto stats = m_clientService.getDashboardStats();
    
    TablePrinter table;
    table.setTitle("📊 ДАШБОРД");
    table.addColumn("Показатель", 30);
    table.addColumn("Значение", 25, TablePrinter::Alignment::Right);
    table.addRow({"Всего клиентов", std::to_string(stats.totalClients)});
    table.addRow({"Активных (30 дней)", std::to_string(stats.active30Days)});
    table.addRow({"Активных (90 дней)", std::to_string(stats.active90Days)});
    
    std::stringstream ss;
    ss << std::fixed << std::setprecision(2) << stats.totalRevenue << " грн";
    table.addRow({"Общая выручка", ss.str()});
    
    table.print();
    waitForKey();
}

void ConsoleUI::showRequiringSurvey() {
    auto clients = m_clientService.getRequiringSurvey();
    
    TablePrinter table;
    table.setTitle("⚠️  КЛИЕНТЫ, ТРЕБУЮЩИЕ ОПРОСА (" + std::to_string(clients.size()) + ")");
    table.addColumn("Код", 12);
    table.addColumn("Название", 40);
    table.addColumn("Тип", 18);
    table.addColumn("Статус", 16);
    
    for (const auto& c : clients) {
        table.addRow({
            c.getCode(),
            c.getName().substr(0, 38),
            c.getClientType().value_or("-"),
            c.getStatusName().value_or("-")
        });
    }
    table.print();
    waitForKey();
}

void ConsoleUI::showStatusDistribution() {
    auto stats = m_clientService.getStatusDistribution();
    
    TablePrinter table;
    table.setTitle("🏷️  РАСПРЕДЕЛЕНИЕ ПО СТАТУСАМ");
    table.addColumn("Статус", 22);
    table.addColumn("Количество", 12, TablePrinter::Alignment::Right);
    table.addColumn("%", 10, TablePrinter::Alignment::Right);
    
    for (const auto& s : stats) {
        std::stringstream ss;
        ss << std::fixed << std::setprecision(1) << s.percentage;
        table.addRow({s.statusName, std::to_string(s.count), ss.str() + "%"});
    }
    table.print();
    waitForKey();
}

void ConsoleUI::showDirectionDistribution() {
    auto stats = m_clientService.getDirectionDistribution();
    
    TablePrinter table;
    table.setTitle("🎯 РАСПРЕДЕЛЕНИЕ ПО НАПРАВЛЕНИЯМ");
    table.addColumn("Направление", 32);
    table.addColumn("Количество", 12, TablePrinter::Alignment::Right);
    table.addColumn("%", 10, TablePrinter::Alignment::Right);
    
    for (const auto& d : stats) {
        std::stringstream ss;
        ss << std::fixed << std::setprecision(1) << d.percentage;
        table.addRow({d.directionName, std::to_string(d.count), ss.str() + "%"});
    }
    table.print();
    waitForKey();
}

void ConsoleUI::showProducts() {
    auto products = m_productService.getAll();
    
    TablePrinter table;
    table.setTitle("📦 ТОВАРЫ (первые 20)");
    table.addColumn("Код", 12);
    table.addColumn("Название", 45);
    table.addColumn("Направление", 22);
    
    int count = 0;
    for (const auto& p : products) {
        table.addRow({
            p.getCode(),
            p.getName().substr(0, 43),
            p.getDirectionName().value_or("-")
        });
        if (++count >= 20) break;
    }
    table.print();
    waitForKey();
}

void ConsoleUI::showClientList() {
    auto clients = m_recService.getClientList();
    
    TablePrinter table;
    table.setTitle("👥 ВЫБЕРИТЕ КЛИЕНТА ДЛЯ РЕКОМЕНДАЦИЙ");
    table.addColumn("Код", 12);
    table.addColumn("Название", 50);
    
    for (const auto& [code, name] : clients) {
        table.addRow({code, name});
    }
    table.print();
    
    std::cout << "\nВведите код клиента (или 0 для выхода): ";
    std::string code;
    std::getline(std::cin, code);
    
    if (code != "0" && !code.empty()) {
        showRecommendations(code);
    }
}

void ConsoleUI::showRecommendations(const std::string& clientCode) {
    auto recs = m_recService.getForClient(clientCode);
    
    if (recs.empty()) {
        std::cout << "\nНет рекомендаций для данного клиента.\n";
        waitForKey();
        return;
    }
    
    TablePrinter table;
    table.setTitle("💡 РЕКОМЕНДАЦИИ ДЛЯ КЛИЕНТА: " + recs[0].clientName);
    table.addColumn("#", 3, TablePrinter::Alignment::Center);
    table.addColumn("Код товара", 12);
    table.addColumn("Название", 40);
    table.addColumn("Причина", 30);
    table.addColumn("На складе", 10, TablePrinter::Alignment::Right);
    
    int index = 1;
    for (const auto& rec : recs) {
        std::stringstream stock;
        stock << std::fixed << std::setprecision(1) << rec.inStockBalance;
        table.addRow({
            std::to_string(index++),
            rec.productCode,
            rec.productName.substr(0, 38),
            rec.reason,
            stock.str()
        });
    }
    table.print();
    waitForKey();
}

} // namespace utsk
EOF

echo "📄 Обновление src/main_console.cpp..."
cat > src/main_console.cpp << 'EOF'
#include "core/Config.hpp"
#include "core/Logger.hpp"
#include "core/Database.hpp"
#include "services/ClientService.hpp"
#include "services/ProductService.hpp"
#include "services/RecommendationService.hpp"
#include "ui/ConsoleUI.hpp"
#include <iostream>

using namespace utsk;

int main() {
    Logger::getInstance().init("", Logger::Level::INFO);
    
    LOG_INFO("UTSK Intelligent Sales - Console v1.0.0");
    
    Config config;
    if (!config.load("config/db_config.json")) {
        std::cerr << "Failed to load config/db_config.json!" << std::endl;
        return 1;
    }
    
    // Подключение к БД (типы уже совпадают!)
    Database db;
    if (!db.connect(config.getDatabaseInfo())) {
        std::cerr << "Failed to connect to database!" << std::endl;
        return 1;
    }
    
    ClientService clientService(db);
    ProductService productService(db);
    RecommendationService recService(db);
    
    ConsoleUI ui(db, clientService, productService, recService);
    ui.run();
    
    db.disconnect();
    LOG_INFO("Application finished");
    
    return 0;
}
EOF

echo "✅ Все исправления применены!"
echo "🔨 Компиляция..."

cmake --build build -j $(nproc)

echo "🎉 Готово! Для запуска выполните: ./build/utsk_console"
EOF
```
