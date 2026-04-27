#!/bin/bash

echo "🚀 Начинаем генерацию файлов для Части 6 (Консольный UI)..."

# Создаем директории
mkdir -p include/ui src/ui src/core src/services

echo "📁 Создание include/ui/TablePrinter.hpp..."
cat > include/ui/TablePrinter.hpp << 'EOF'
#ifndef TABLE_PRINTER_HPP
#define TABLE_PRINTER_HPP

#include <vector>
#include <string>
#include <iostream>
#include <iomanip>
#include <algorithm>

namespace utsk {

/**
 * @brief Класс для красивого вывода таблиц в консоль
 */
class TablePrinter {
public:
    enum class Alignment { Left, Right, Center };

    struct Column {
        std::string header;
        int width;
        Alignment align;
    };

    TablePrinter() = default;

    TablePrinter& setTitle(const std::string& title);
    TablePrinter& addColumn(const std::string& header, int width, 
                            Alignment align = Alignment::Left);
    TablePrinter& addRow(const std::vector<std::string>& row);
    TablePrinter& addSeparator();
    void print();
    void clear();

private:
    void printLine(char left, char mid, char right, char fill);
    void printRow(const std::vector<std::string>& row);
    std::string alignText(const std::string& text, int width, Alignment align);

    std::string m_title;
    std::vector<Column> m_columns;
    std::vector<std::vector<std::string>> m_rows;
};

} // namespace utsk

#endif // TABLE_PRINTER_HPP
EOF

echo "📄 Создание src/ui/TablePrinter.cpp..."
cat > src/ui/TablePrinter.cpp << 'EOF'
#include "ui/TablePrinter.hpp"

namespace utsk {

TablePrinter& TablePrinter::setTitle(const std::string& title) {
    m_title = title;
    return *this;
}

TablePrinter& TablePrinter::addColumn(const std::string& header, int width, Alignment align) {
    m_columns.push_back({header, width, align});
    return *this;
}

TablePrinter& TablePrinter::addRow(const std::vector<std::string>& row) {
    m_rows.push_back(row);
    return *this;
}

TablePrinter& TablePrinter::addSeparator() {
    m_rows.push_back({"---"});
    return *this;
}

void TablePrinter::clear() {
    m_title.clear();
    m_columns.clear();
    m_rows.clear();
}

std::string TablePrinter::alignText(const std::string& text, int width, Alignment align) {
    if (static_cast<int>(text.length()) >= width) {
        return text.substr(0, width - 2) + "..";
    }
    
    int padding = width - text.length();
    
    switch (align) {
        case Alignment::Left:
            return text + std::string(padding, ' ');
        case Alignment::Right:
            return std::string(padding, ' ') + text;
        case Alignment::Center:
            int leftPad = padding / 2;
            int rightPad = padding - leftPad;
            return std::string(leftPad, ' ') + text + std::string(rightPad, ' ');
    }
    return text;
}

void TablePrinter::printLine(char left, char mid, char right, char fill) {
    std::cout << left;
    for (size_t i = 0; i < m_columns.size(); ++i) {
        std::cout << std::string(m_columns[i].width, fill);
        if (i < m_columns.size() - 1) {
            std::cout << mid;
        }
    }
    std::cout << right << "\n";
}

void TablePrinter::printRow(const std::vector<std::string>& row) {
    if (row.size() == 1 && row[0] == "---") {
        printLine('├', '┼', '┤', '─');
        return;
    }
    
    std::cout << "│";
    for (size_t i = 0; i < m_columns.size() && i < row.size(); ++i) {
        std::cout << alignText(row[i], m_columns[i].width, m_columns[i].align);
        if (i < m_columns.size() - 1) {
            std::cout << "│";
        }
    }
    std::cout << "│\n";
}

void TablePrinter::print() {
    if (m_columns.empty()) return;
    
    // Заголовок
    if (!m_title.empty()) {
        int totalWidth = 1; // начальная граница
        for (const auto& col : m_columns) {
            totalWidth += col.width + 1; // ширина + разделитель
        }
        
        std::cout << "\n╔" << std::string(totalWidth, '═') << "╗\n";
        std::cout << "║" << alignText(m_title, totalWidth, Alignment::Center) << "║\n";
        printLine('╠', '╦', '╣', '═');
    } else {
        printLine('┌', '┬', '┐', '─');
    }
    
    // Заголовки колонок
    std::vector<std::string> headers;
    for (const auto& col : m_columns) {
        headers.push_back(col.header);
    }
    printRow(headers);
    printLine('├', '┼', '┤', '─');
    
    // Данные
    for (const auto& row : m_rows) {
        printRow(row);
    }
    
    // Нижняя граница
    printLine('└', '┴', '┘', '─');
    std::cout << "\n";
}

} // namespace utsk
EOF

echo "📁 Создание include/ui/ConsoleMenu.hpp..."
cat > include/ui/ConsoleMenu.hpp << 'EOF'
#ifndef CONSOLE_MENU_HPP
#define CONSOLE_MENU_HPP

#include <vector>
#include <string>
#include <functional>

namespace utsk {

/**
 * @brief Простое консольное меню
 */
class ConsoleMenu {
public:
    struct MenuItem {
        std::string key;
        std::string description;
        std::function<void()> action;
    };

    ConsoleMenu() = default;

    void setTitle(const std::string& title) { m_title = title; }
    void addItem(const std::string& key, const std::string& description, 
                 std::function<void()> action);
    void addSeparator(const std::string& text = "");
    void run();
    void exit();

private:
    void display();
    void clearScreen();

    std::string m_title = "MENU";
    std::vector<MenuItem> m_items;
    bool m_running = false;
};

} // namespace utsk

#endif // CONSOLE_MENU_HPP
EOF

echo "📄 Создание src/ui/ConsoleMenu.cpp..."
cat > src/ui/ConsoleMenu.cpp << 'EOF'
#include "ui/ConsoleMenu.hpp"
#include <iostream>
#include <limits>

namespace utsk {

void ConsoleMenu::addItem(const std::string& key, const std::string& description, 
                          std::function<void()> action) {
    m_items.push_back({key, description, action});
}

void ConsoleMenu::addSeparator(const std::string& text) {
    if (text.empty()) {
        m_items.push_back({"---", "", nullptr});
    } else {
        m_items.push_back({"---", text, nullptr});
    }
}

void ConsoleMenu::clearScreen() {
    std::cout << "\033[2J\033[1;1H";
}

void ConsoleMenu::display() {
    clearScreen();
    
    std::cout << "\n╔══════════════════════════════════════════════════════╗\n";
    std::cout << "║          " << m_title << "\n";
    std::cout << "╠══════════════════════════════════════════════════════╣\n";
    
    for (const auto& item : m_items) {
        if (item.key == "---") {
            if (item.description.empty()) {
                std::cout << "║                                                      ║\n";
            } else {
                std::cout << "║  " << item.description << "\n";
            }
        } else {
            std::cout << "║  [" << item.key << "] " << item.description;
            int len = 5 + item.key.length() + item.description.length();
            int padding = 52 - len;
            if (padding > 0) {
                std::cout << std::string(padding, ' ');
            }
            std::cout << "║\n";
        }
    }
    
    std::cout << "╚══════════════════════════════════════════════════════╝\n";
    std::cout << "\nВыберите действие: ";
}

void ConsoleMenu::run() {
    m_running = true;
    
    while (m_running) {
        display();
        
        std::string input;
        std::cin >> input;
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        
        bool found = false;
        for (const auto& item : m_items) {
            if (item.key == input && item.action) {
                item.action();
                found = true;
                break;
            }
        }
        
        if (!found && input != "0" && input != "q") {
            std::cout << "\nНеверный выбор. Нажмите Enter для продолжения...";
            std::cin.get();
        }
    }
}

void ConsoleMenu::exit() {
    m_running = false;
}

} // namespace utsk
EOF

echo "📁 Создание include/ui/ConsoleUI.hpp..."
cat > include/ui/ConsoleUI.hpp << 'EOF'
#ifndef CONSOLE_UI_HPP
#define CONSOLE_UI_HPP

#include "core/Database.hpp"
#include "services/ClientService.hpp"
#include "services/ProductService.hpp"
#include "ui/ConsoleMenu.hpp"
#include "ui/TablePrinter.hpp"

namespace utsk {

/**
 * @brief Главный класс консольного интерфейса
 */
class ConsoleUI {
public:
    ConsoleUI(Database& db, ClientService& clientSvc, ProductService& productSvc);
    ~ConsoleUI() = default;

    void run();

private:
    void showDashboard();
    void showClients();
    void showProducts();
    void showStatusDistribution();
    void showDirectionDistribution();
    void showRequiringSurvey();
    void waitForKey();

    Database& m_db;
    ClientService& m_clientService;
    ProductService& m_productService;
    ConsoleMenu m_menu;
};

} // namespace utsk

#endif // CONSOLE_UI_HPP
EOF

echo "📄 Создание src/ui/ConsoleUI.cpp..."
cat > src/ui/ConsoleUI.cpp << 'EOF'
#include "ui/ConsoleUI.hpp"
#include "core/Logger.hpp"
#include <iostream>
#include <iomanip>
#include <sstream>

namespace utsk {

ConsoleUI::ConsoleUI(Database& db, ClientService& clientSvc, ProductService& productSvc)
    : m_db(db)
    , m_clientService(clientSvc)
    , m_productService(productSvc) {
    
    m_menu.setTitle("UTSK INTELLIGENT SALES v1.0.0");
    
    m_menu.addItem("1", "📊 Дашборд", 
        [this]() { showDashboard(); });
    m_menu.addItem("2", "👥 Клиенты (требуют опроса)", 
        [this]() { showRequiringSurvey(); });
    m_menu.addItem("3", "🏷️  Статусы клиентов", 
        [this]() { showStatusDistribution(); });
    m_menu.addItem("4", "🎯 Направления деятельности", 
        [this]() { showDirectionDistribution(); });
    m_menu.addItem("5", "📦 Товары", 
        [this]() { showProducts(); });
    m_menu.addSeparator();
    m_menu.addItem("0", "🚪 Выход", 
        [this]() { m_menu.exit(); });
}

void ConsoleUI::run() {
    LOG_INFO("Starting console UI");
    m_menu.run();
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
    
    ss.str("");
    ss << std::fixed << std::setprecision(2) << stats.revenue30Days << " грн";
    table.addRow({"Выручка за 30 дней", ss.str()});
    
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

void ConsoleUI::waitForKey() {
    std::cout << "\nНажмите Enter для продолжения...";
    std::cin.get();
}

} // namespace utsk
EOF

echo "📄 Перезапись src/core/Logger.cpp (очищенная версия)..."
cat > src/core/Logger.cpp << 'EOF'
#include "core/Logger.hpp"
#include <iostream>
#include <chrono>
#include <iomanip>
#include <ctime>

namespace utsk {

namespace Color {
    const std::string RESET   = "\033[0m";
    const std::string RED     = "\033[31m";
    const std::string GREEN   = "\033[32m";
    const std::string YELLOW  = "\033[33m";
    const std::string CYAN    = "\033[36m";
    const std::string BOLD    = "\033[1m";
}

Logger& Logger::getInstance() {
    static Logger instance;
    return instance;
}

Logger::Logger() = default;

Logger::~Logger() {
    if (m_file.is_open()) {
        m_file.close();
    }
}

void Logger::init(const std::string& logFile, Level level) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_level = level;
    
    if (!logFile.empty()) {
        m_file.open(logFile, std::ios::out | std::ios::app);
    }
    
    m_initialized = true;
}

void Logger::log(Level level, const std::string& message) {
    if (level < m_level) return;
    
    std::lock_guard<std::mutex> lock(m_mutex);
    
    std::string timestamp = getTimestamp();
    std::string levelStr = levelToString(level);
    std::string fullMessage = "[" + timestamp + "] [" + levelStr + "] " + message;
    
    if (m_useColors) {
        std::cout << colorize(level, fullMessage) << std::endl;
    } else {
        std::cout << fullMessage << std::endl;
    }
    
    if (m_file.is_open()) {
        m_file << fullMessage << std::endl;
        m_file.flush();
    }
}

std::string Logger::levelToString(Level level) {
    switch (level) {
        case Level::DEBUG:   return "DEBUG";
        case Level::INFO:    return "INFO ";
        case Level::WARNING: return "WARN ";
        case Level::ERROR:   return "ERROR";
        default:             return "???? ";
    }
}

std::string Logger::getTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
        now.time_since_epoch()) % 1000;
    
    std::stringstream ss;
    ss << std::put_time(std::localtime(&time_t), "%Y-%m-%d %H:%M:%S");
    ss << "." << std::setfill('0') << std::setw(3) << ms.count();
    return ss.str();
}

std::string Logger::colorize(Level level, const std::string& text) {
    switch (level) {
        case Level::DEBUG:   return Color::CYAN + text + Color::RESET;
        case Level::INFO:    return Color::GREEN + text + Color::RESET;
        case Level::WARNING: return Color::YELLOW + Color::BOLD + text + Color::RESET;
        case Level::ERROR:   return Color::RED + Color::BOLD + text + Color::RESET;
        default:             return text;
    }
}

} // namespace utsk
EOF

echo "📄 Перезапись src/services/ClientService.cpp (очищенная версия)..."
cat > src/services/ClientService.cpp << 'EOF'
#include "services/ClientService.hpp"
#include "core/Logger.hpp"
#include <sstream>

namespace utsk {

ClientService::ClientService(Database& db) : m_db(db) {}

ClientService::DashboardStats ClientService::getDashboardStats() {
    DashboardStats stats = {0, 0, 0, 0.0, 0.0};
    
    const std::string query = R"(
        SELECT 
            COUNT(DISTINCT c.code) as total_clients,
            COUNT(DISTINCT CASE WHEN c.last_purchase_date >= CURRENT_DATE - INTERVAL '30 days' THEN c.code END) as active_30d,
            COUNT(DISTINCT CASE WHEN c.last_purchase_date >= CURRENT_DATE - INTERVAL '90 days' THEN c.code END) as active_90d,
            COALESCE(SUM(d.total_amount), 0) as total_revenue,
            COALESCE(SUM(CASE WHEN d.invoice_date >= CURRENT_DATE - INTERVAL '30 days' THEN d.total_amount END), 0) as revenue_30d
        FROM clients c
        LEFT JOIN documents d ON d.client_code = c.code
    )";
    
    try {
        auto result = m_db.execute(query);
        
        if (!result.empty()) {
            auto row = result[0];
            stats.totalClients = row["total_clients"].as<int>();
            stats.active30Days = row["active_30d"].as<int>();
            stats.active90Days = row["active_90d"].as<int>();
            stats.totalRevenue = row["total_revenue"].as<double>();
            stats.revenue30Days = row["revenue_30d"].as<double>();
        }
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Dashboard query failed: ") + e.what());
    }
    
    return stats;
}

std::vector<ClientService::StatusStats> ClientService::getStatusDistribution() {
    std::vector<StatusStats> stats;
    
    const std::string query = R"(
        SELECT 
            sr.status_name,
            COUNT(c.code) as count,
            ROUND(COUNT(c.code) * 100.0 / (SELECT COUNT(*) FROM clients), 2) as percentage
        FROM clients c
        JOIN status_rules sr ON c.current_status_id = sr.id
        GROUP BY sr.status_name, sr.priority
        ORDER BY sr.priority
    )";
    
    try {
        auto result = m_db.execute(query);
        
        for (const auto& row : result) {
            StatusStats stat;
            stat.statusName = row["status_name"].as<std::string>();
            stat.count = row["count"].as<int>();
            stat.percentage = row["percentage"].as<double>();
            stats.push_back(stat);
        }
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Status query failed: ") + e.what());
    }
    
    return stats;
}

std::vector<ClientService::DirectionStats> ClientService::getDirectionDistribution() {
    std::vector<DirectionStats> stats;
    
    const std::string query = R"(
        SELECT 
            ad.name as direction_name,
            COUNT(c.code) as count,
            ROUND(COUNT(c.code) * 100.0 / (SELECT COUNT(*) FROM clients WHERE activity_direction_id IS NOT NULL), 2) as percentage
        FROM clients c
        JOIN activity_directions ad ON c.activity_direction_id = ad.id
        GROUP BY ad.name
        ORDER BY count DESC
    )";
    
    try {
        auto result = m_db.execute(query);
        
        for (const auto& row : result) {
            DirectionStats stat;
            stat.directionName = row["direction_name"].as<std::string>();
            stat.count = row["count"].as<int>();
            stat.percentage = row["percentage"].as<double>();
            stats.push_back(stat);
        }
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Direction query failed: ") + e.what());
    }
    
    return stats;
}

std::vector<Client> ClientService::getRequiringSurvey() {
    std::vector<Client> clients;
    
    const std::string query = R"(
        SELECT code, name, client_type, 
               sr.status_name as current_status,
               last_purchase_date
        FROM clients c
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        WHERE requires_survey = TRUE
        ORDER BY last_purchase_date DESC NULLS LAST
        LIMIT 10
    )";
    
    try {
        auto result = m_db.execute(query);
        
        for (const auto& row : result) {
            Client client;
            client.setCode(row["code"].as<std::string>());
            client.setName(row["name"].as<std::string>());
            
            if (!row["client_type"].is_null())
                client.setClientType(row["client_type"].as<std::string>());
            if (!row["current_status"].is_null())
                client.setStatusName(row["current_status"].as<std::string>());
            if (!row["last_purchase_date"].is_null())
                client.setLastPurchaseDate(row["last_purchase_date"].as<std::string>());
            
            client.setRequiresSurvey(true);
            clients.push_back(std::move(client));
        }
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Survey query failed: ") + e.what());
    }
    
    return clients;
}

void ClientService::updateAnalytics(const std::string& clientCode) {
    try {
        if (clientCode.empty()) {
            m_db.execute("SELECT update_client_analytics()");
        } else {
            m_db.executeParams("SELECT update_client_analytics($1)", {clientCode});
        }
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Update analytics failed: ") + e.what());
    }
}

} // namespace utsk
EOF

echo "📄 Обновление src/main_console.cpp..."
cat > src/main_console.cpp << 'EOF'
#include <iostream>
#include "core/Config.hpp"
#include "core/Logger.hpp"
#include "core/Database.hpp"
#include "services/ClientService.hpp"
#include "services/ProductService.hpp"
#include "ui/ConsoleUI.hpp"

using namespace utsk;

int main() {
    Logger::getInstance().init("", Logger::Level::INFO);
    
    // Загрузка конфигурации (.env содержит правильные настройки для подключения)
    Config config;
    if (!config.load(".env")) {
        std::cerr << "Failed to load .env!" << std::endl;
        return 1;
    }
    
    // Подключение к БД с конвертацией структур данных
    auto configInfo = config.getDatabaseInfo();
    Database::ConnectionInfo dbInfo;
    dbInfo.host = configInfo.host;
    dbInfo.port = configInfo.port;
    dbInfo.dbname = configInfo.dbname;
    dbInfo.user = configInfo.user;
    dbInfo.password = configInfo.password;

    Database db;
    if (!db.connect(dbInfo)) {
        std::cerr << "Failed to connect to database!" << std::endl;
        return 1;
    }
    
    // Сервисы
    ClientService clientService(db);
    ProductService productService(db);
    
    // Запуск UI
    ConsoleUI ui(db, clientService, productService);
    ui.run();
    
    db.disconnect();
    LOG_INFO("Application finished successfully");
    
    return 0;
}
EOF

echo "✅ Все файлы успешно созданы!"
echo "🔨 Запускаю сборку проекта..."

# Сборка
cmake --build build -j $(nproc)

echo "🎉 Готово! Чтобы запустить программу, выполните:"
echo "./build/utsk_console"
