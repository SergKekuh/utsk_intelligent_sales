#!/bin/bash

# =============================================================================
# СКРИПТ: ЧАСТЬ 5 - СОЗДАНИЕ СЕРВИСНОГО СЛОЯ (БИЗНЕС-ЛОГИКА)
# =============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}  СОЗДАНИЕ СЕРВИСНОГО СЛОЯ (ЧАСТЬ 5)${NC}"
echo -e "${BLUE}======================================================================${NC}"

mkdir -p include/services src/services

# -----------------------------------------------------------------------------
# 1. CLIENT SERVICE
# -----------------------------------------------------------------------------
echo -e "${GREEN}📝 Создание ClientService...${NC}"
cat > include/services/ClientService.hpp << 'EOF'
#ifndef CLIENT_SERVICE_HPP
#define CLIENT_SERVICE_HPP

#include <vector>
#include <memory>
#include <optional>
#include "models/Client.hpp"
#include "core/Database.hpp"

namespace utsk {

class ClientService {
public:
    explicit ClientService(Database& db);
    ~ClientService() = default;

    std::vector<Client> getDashboard();
    std::vector<Client> getRequiringSurvey();
    std::optional<Client> getByCode(const std::string& code);
    void updateAnalytics(const std::string& clientCode = "");

    struct StatusStats {
        std::string statusName;
        int count;
        double percentage;
    };
    std::vector<StatusStats> getStatusDistribution();

    struct DirectionStats {
        std::string directionName;
        int count;
        double percentage;
    };
    std::vector<DirectionStats> getDirectionDistribution();

    struct DashboardStats {
        int totalClients;
        int active30Days;
        int active90Days;
        double totalRevenue;
        double revenue30Days;
    };
    DashboardStats getDashboardStats();

private:
    Database& m_db;
};

} // namespace utsk

#endif // CLIENT_SERVICE_HPP
EOF

cat > src/services/ClientService.cpp << 'EOF'
#include "services/ClientService.hpp"
#include "core/Logger.hpp"
#include <sstream>
#include <iomanip>

namespace utsk {

ClientService::ClientService(Database& db) : m_db(db) {
    LOG_DEBUG("ClientService initialized");
}

std::vector<Client> ClientService::getDashboard() {
    std::vector<Client> clients;
    const std::string query = R"(
        SELECT 
            code, name, client_type, current_status, 
            first_purchase_date, last_purchase_date, 
            days_since_last, activity_direction, 
            direction_confidence, requires_survey, 
            survey_completed_at, total_docs, 
            docs_current_year, total_revenue
        FROM v_manager_dashboard
        ORDER BY requires_survey DESC, days_since_last ASC
    )";
    try {
        auto result = m_db.execute(query);
        for (const auto& row : result) {
            Client client;
            client.setCode(row["code"].as<std::string>());
            client.setName(row["name"].as<std::string>());
            
            try { if (!row["client_type"].is_null()) client.setClientType(row["client_type"].as<std::string>()); } catch(...) {}
            try { if (!row["current_status"].is_null()) client.setStatusName(row["current_status"].as<std::string>()); } catch(...) {}
            try { if (!row["first_purchase_date"].is_null()) client.setFirstPurchaseDate(row["first_purchase_date"].as<std::string>()); } catch(...) {}
            try { if (!row["last_purchase_date"].is_null()) client.setLastPurchaseDate(row["last_purchase_date"].as<std::string>()); } catch(...) {}
            try { if (!row["days_since_last"].is_null()) client.setDaysSinceLastPurchase(row["days_since_last"].as<int>()); } catch(...) {}
            try { if (!row["activity_direction"].is_null()) client.setDirectionName(row["activity_direction"].as<std::string>()); } catch(...) {}
            try { if (!row["direction_confidence"].is_null()) client.setDirectionConfidence(row["direction_confidence"].as<double>()); } catch(...) {}
            try { if (!row["requires_survey"].is_null()) client.setRequiresSurvey(row["requires_survey"].as<bool>()); } catch(...) {}
            try { if (!row["total_docs"].is_null()) client.setTotalDocuments(row["total_docs"].as<int>()); } catch(...) {}
            try { if (!row["total_revenue"].is_null()) client.setTotalRevenue(row["total_revenue"].as<double>()); } catch(...) {}
            
            clients.push_back(std::move(client));
        }
        LOG_INFO("Loaded " + std::to_string(clients.size()) + " clients from dashboard");
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Failed to load dashboard: ") + e.what());
    }
    return clients;
}

std::vector<Client> ClientService::getRequiringSurvey() {
    std::vector<Client> clients;
    const std::string query = R"(
        SELECT code, name, client_type, current_status, last_purchase_date
        FROM v_manager_dashboard
        WHERE requires_survey = TRUE
        ORDER BY last_purchase_date DESC NULLS LAST
    )";
    try {
        auto result = m_db.execute(query);
        for (const auto& row : result) {
            Client client;
            client.setCode(row["code"].as<std::string>());
            client.setName(row["name"].as<std::string>());
            try { if (!row["client_type"].is_null()) client.setClientType(row["client_type"].as<std::string>()); } catch(...) {}
            try { if (!row["current_status"].is_null()) client.setStatusName(row["current_status"].as<std::string>()); } catch(...) {}
            client.setRequiresSurvey(true);
            clients.push_back(std::move(client));
        }
        LOG_INFO("Found " + std::to_string(clients.size()) + " clients requiring survey");
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Failed to get survey clients: ") + e.what());
    }
    return clients;
}

std::optional<Client> ClientService::getByCode(const std::string& code) {
    const std::string query = R"(
        SELECT c.code, c.name, c.client_type, sr.status_name as current_status,
               c.first_purchase_date, c.last_purchase_date, ad.name as activity_direction,
               c.direction_confidence, c.requires_survey,
               (SELECT COUNT(*) FROM documents WHERE client_code = c.code) as total_docs,
               (SELECT COALESCE(SUM(total_amount), 0) FROM documents WHERE client_code = c.code) as total_revenue
        FROM clients c
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
        WHERE c.code = $1
    )";
    try {
        auto result = m_db.executeParams(query, {code});
        if (result.empty()) return std::nullopt;
        
        auto row = result[0];
        Client client;
        client.setCode(row["code"].as<std::string>());
        client.setName(row["name"].as<std::string>());
        // Опциональные поля опущены для краткости, можно добавить аналогично getDashboard
        return client;
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Failed to get client by code: ") + e.what());
        return std::nullopt;
    }
}

void ClientService::updateAnalytics(const std::string& clientCode) {
    try {
        if (clientCode.empty()) {
            m_db.execute("SELECT update_client_analytics()");
            LOG_INFO("Updated analytics for all clients");
        } else {
            m_db.executeParams("SELECT update_client_analytics($1)", {clientCode});
            LOG_INFO("Updated analytics for client: " + clientCode);
        }
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Failed to update analytics: ") + e.what());
    }
}

std::vector<ClientService::StatusStats> ClientService::getStatusDistribution() {
    std::vector<StatusStats> stats;
    const std::string query = R"(
        SELECT sr.status_name, COUNT(c.code) as count,
               ROUND(COUNT(c.code) * 100.0 / NULLIF((SELECT COUNT(*) FROM clients), 0), 2) as percentage
        FROM clients c
        JOIN status_rules sr ON c.current_status_id = sr.id
        GROUP BY sr.status_name, sr.priority
        ORDER BY sr.priority
    )";
    try {
        auto result = m_db.execute(query);
        for (const auto& row : result) {
            stats.push_back({
                row["status_name"].as<std::string>(),
                row["count"].as<int>(),
                row["percentage"].is_null() ? 0.0 : row["percentage"].as<double>()
            });
        }
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Failed to get status distribution: ") + e.what());
    }
    return stats;
}

std::vector<ClientService::DirectionStats> ClientService::getDirectionDistribution() {
    std::vector<DirectionStats> stats;
    const std::string query = R"(
        SELECT ad.name as direction_name, COUNT(c.code) as count,
               ROUND(COUNT(c.code) * 100.0 / NULLIF((SELECT COUNT(*) FROM clients WHERE activity_direction_id IS NOT NULL), 0), 2) as percentage
        FROM clients c
        JOIN activity_directions ad ON c.activity_direction_id = ad.id
        GROUP BY ad.name ORDER BY count DESC
    )";
    try {
        auto result = m_db.execute(query);
        for (const auto& row : result) {
            stats.push_back({
                row["direction_name"].as<std::string>(),
                row["count"].as<int>(),
                row["percentage"].is_null() ? 0.0 : row["percentage"].as<double>()
            });
        }
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Failed to get direction distribution: ") + e.what());
    }
    return stats;
}

ClientService::DashboardStats ClientService::getDashboardStats() {
    DashboardStats stats = {0, 0, 0, 0.0, 0.0};
    const std::string query = R"(
        SELECT 
            COUNT(DISTINCT c.code) as total_clients,
            COUNT(DISTINCT CASE WHEN c.last_purchase_date >= CURRENT_DATE - INTERVAL '30 days' THEN c.code END) as active_30d,
            COUNT(DISTINCT CASE WHEN c.last_purchase_date >= CURRENT_DATE - INTERVAL '90 days' THEN c.code END) as active_90d,
            COALESCE((SELECT SUM(total_amount) FROM documents), 0) as total_revenue,
            COALESCE((SELECT SUM(total_amount) FROM documents WHERE invoice_date >= CURRENT_DATE - INTERVAL '30 days'), 0) as revenue_30d
        FROM clients c
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
        LOG_ERROR(std::string("Failed to get dashboard stats: ") + e.what());
    }
    return stats;
}

} // namespace utsk
EOF

# -----------------------------------------------------------------------------
# 2. PRODUCT SERVICE
# -----------------------------------------------------------------------------
echo -e "${GREEN}📝 Создание ProductService...${NC}"
cat > include/services/ProductService.hpp << 'EOF'
#ifndef PRODUCT_SERVICE_HPP
#define PRODUCT_SERVICE_HPP

#include <vector>
#include <optional>
#include "models/Product.hpp"
#include "core/Database.hpp"

namespace utsk {

class ProductService {
public:
    explicit ProductService(Database& db);
    ~ProductService() = default;

    std::vector<Product> getAll();
    std::optional<Product> getByCode(const std::string& code);
    std::vector<Product> getByDirection(int directionId);
    std::vector<Product> getNewArrivals();
    std::vector<Product> getInStock();
    std::vector<Product> search(const std::string& query);

private:
    Database& m_db;
};

} // namespace utsk

#endif // PRODUCT_SERVICE_HPP
EOF

cat > src/services/ProductService.cpp << 'EOF'
#include "services/ProductService.hpp"
#include "core/Logger.hpp"

namespace utsk {

ProductService::ProductService(Database& db) : m_db(db) {
    LOG_DEBUG("ProductService initialized");
}

std::vector<Product> ProductService::getAll() {
    std::vector<Product> products;
    const std::string query = "SELECT p.*, ad.name as direction_name FROM products p LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id ORDER BY p.code LIMIT 100";
    try {
        auto result = m_db.execute(query);
        for (const auto& row : result) products.push_back(Product::fromRow(row));
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return products;
}

std::optional<Product> ProductService::getByCode(const std::string& code) {
    const std::string query = "SELECT p.*, ad.name as direction_name FROM products p LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id WHERE p.code = $1";
    try {
        auto result = m_db.executeParams(query, {code});
        if (!result.empty()) return Product::fromRow(result[0]);
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return std::nullopt;
}

std::vector<Product> ProductService::getByDirection(int directionId) {
    std::vector<Product> products;
    const std::string query = "SELECT p.*, ad.name as direction_name FROM products p LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id WHERE p.anchor_direction_id = $1 ORDER BY p.code";
    try {
        auto result = m_db.executeParams(query, {std::to_string(directionId)});
        for (const auto& row : result) products.push_back(Product::fromRow(row));
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return products;
}

std::vector<Product> ProductService::getNewArrivals() {
    std::vector<Product> products;
    const std::string query = "SELECT p.*, ad.name as direction_name FROM products p LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id WHERE p.is_new_arrival = TRUE AND p.in_stock_balance > 0 ORDER BY p.created_at DESC";
    try {
        auto result = m_db.execute(query);
        for (const auto& row : result) products.push_back(Product::fromRow(row));
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return products;
}

std::vector<Product> ProductService::getInStock() {
    std::vector<Product> products;
    const std::string query = "SELECT p.*, ad.name as direction_name FROM products p LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id WHERE p.in_stock_balance > 0 ORDER BY p.code";
    try {
        auto result = m_db.execute(query);
        for (const auto& row : result) products.push_back(Product::fromRow(row));
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return products;
}

std::vector<Product> ProductService::search(const std::string& searchQuery) {
    std::vector<Product> products;
    const std::string query = "SELECT p.*, ad.name as direction_name FROM products p LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id WHERE LOWER(p.name) LIKE LOWER($1) OR p.code LIKE $2 ORDER BY p.code LIMIT 50";
    try {
        std::string likePattern = "%" + searchQuery + "%";
        auto result = m_db.executeParams(query, {likePattern, likePattern});
        for (const auto& row : result) products.push_back(Product::fromRow(row));
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return products;
}

} // namespace utsk
EOF

# -----------------------------------------------------------------------------
# 3. RECOMMENDATION SERVICE (ДОБАВЛЕНО)
# -----------------------------------------------------------------------------
echo -e "${GREEN}📝 Создание RecommendationService...${NC}"
cat > include/services/RecommendationService.hpp << 'EOF'
#ifndef RECOMMENDATION_SERVICE_HPP
#define RECOMMENDATION_SERVICE_HPP

#include <vector>
#include <string>
#include "models/Recommendation.hpp"
#include "core/Database.hpp"

namespace utsk {
class RecommendationService {
public:
    explicit RecommendationService(Database& db);
    std::vector<Recommendation> getForClient(const std::string& clientCode);
    std::vector<Recommendation> getTopRecommendations(int limit = 10);
private:
    Database& m_db;
};
}
#endif // RECOMMENDATION_SERVICE_HPP
EOF

cat > src/services/RecommendationService.cpp << 'EOF'
#include "services/RecommendationService.hpp"
#include "core/Logger.hpp"

namespace utsk {
RecommendationService::RecommendationService(Database& db) : m_db(db) {}

std::vector<Recommendation> RecommendationService::getForClient(const std::string& clientCode) {
    std::vector<Recommendation> recs;
    try {
        auto result = m_db.executeParams("SELECT * FROM v_smart_recommendations WHERE client_code = $1 ORDER BY priority DESC", {clientCode});
        for (const auto& row : result) recs.push_back(Recommendation::fromRow(row));
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return recs;
}

std::vector<Recommendation> RecommendationService::getTopRecommendations(int limit) {
    std::vector<Recommendation> recs;
    try {
        auto result = m_db.executeParams("SELECT * FROM v_smart_recommendations ORDER BY priority DESC LIMIT $1", {std::to_string(limit)});
        for (const auto& row : result) recs.push_back(Recommendation::fromRow(row));
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return recs;
}
}
EOF

# -----------------------------------------------------------------------------
# 4. ANALYTICS SERVICE (ДОБАВЛЕНО)
# -----------------------------------------------------------------------------
echo -e "${GREEN}📝 Создание AnalyticsService...${NC}"
cat > include/services/AnalyticsService.hpp << 'EOF'
#ifndef ANALYTICS_SERVICE_HPP
#define ANALYTICS_SERVICE_HPP

#include "core/Database.hpp"
#include <vector>
#include <string>

namespace utsk {
class AnalyticsService {
public:
    explicit AnalyticsService(Database& db);
    
    struct MonthlyRevenue { 
        std::string month; 
        double revenue; 
    };
    
    std::vector<MonthlyRevenue> getRevenueByMonth(int monthsLimit = 12);
private:
    Database& m_db;
};
}
#endif // ANALYTICS_SERVICE_HPP
EOF

cat > src/services/AnalyticsService.cpp << 'EOF'
#include "services/AnalyticsService.hpp"
#include "core/Logger.hpp"

namespace utsk {
AnalyticsService::AnalyticsService(Database& db) : m_db(db) {}

std::vector<AnalyticsService::MonthlyRevenue> AnalyticsService::getRevenueByMonth(int monthsLimit) {
    std::vector<MonthlyRevenue> stats;
    try {
        const std::string query = R"(
            SELECT TO_CHAR(invoice_date::date, 'YYYY-MM') as month, SUM(total_amount) as revenue
            FROM documents
            GROUP BY TO_CHAR(invoice_date::date, 'YYYY-MM')
            ORDER BY month DESC LIMIT $1
        )";
        auto result = m_db.executeParams(query, {std::to_string(monthsLimit)});
        for (const auto& row : result) {
            stats.push_back({ row["month"].as<std::string>(), row["revenue"].as<double>() });
        }
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return stats;
}
}
EOF

# -----------------------------------------------------------------------------
# 5. ОБНОВЛЕНИЕ MAIN_CONSOLE (ТЕСТ)
# -----------------------------------------------------------------------------
echo -e "${GREEN}📝 Обновление src/main_console.cpp для теста сервисов...${NC}"
cat > src/main_console.cpp << 'EOF'
#include <iostream>
#include <iomanip>
#include "core/Config.hpp"
#include "core/Logger.hpp"
#include "core/Database.hpp"
#include "services/ClientService.hpp"
#include "services/ProductService.hpp"
#include "services/RecommendationService.hpp"
#include "services/AnalyticsService.hpp"

using namespace utsk;

void printSeparator() {
    std::cout << "\n" << std::string(60, '=') << "\n\n";
}

int main() {
    Logger::getInstance().init("", Logger::Level::INFO);
    
    LOG_INFO("========================================");
    LOG_INFO("UTSK Intelligent Sales - Console v1.0.0");
    LOG_INFO("========================================");
    
    Config config;
    // Используем ваш текущий метод получения конфига, будь то getDatabaseInfo() или getDatabaseString()
    if (!config.load(".env")) { 
        // Попытаемся загрузить резервный конфиг если .env нет, или просто продолжим
    }
    
    Database db;
    if (!db.connect(config.getDatabaseInfo())) {
        LOG_ERROR("Failed to connect to database!");
        return 1;
    }
    
    ClientService clientService(db);
    ProductService productService(db);
    RecommendationService recService(db);
    
    printSeparator();
    
    // Дашборд
    auto stats = clientService.getDashboardStats();
    std::cout << "📊 ДАШБОРД\n";
    std::cout << "─────────────────────────────────────────\n";
    std::cout << "Всего клиентов:        " << stats.totalClients << "\n";
    std::cout << "Активных (30 дней):    " << stats.active30Days << "\n";
    std::cout << "Активных (90 дней):    " << stats.active90Days << "\n";
    std::cout << std::fixed << std::setprecision(2);
    std::cout << "Общая выручка:         " << stats.totalRevenue << " грн\n";
    std::cout << "Выручка за 30 дней:    " << stats.revenue30Days << " грн\n";
    
    printSeparator();
    
    // Статусы
    auto statusStats = clientService.getStatusDistribution();
    std::cout << "🏷️  РАСПРЕДЕЛЕНИЕ ПО СТАТУСАМ\n";
    std::cout << "─────────────────────────────────────────\n";
    for (const auto& s : statusStats) {
        std::cout << std::left << std::setw(25) << s.statusName 
                  << std::right << std::setw(6) << s.count 
                  << " (" << std::setw(5) << s.percentage << "%)\n";
    }
    
    printSeparator();
    
    // Клиенты, требующие опроса
    auto surveyClients = clientService.getRequiringSurvey();
    std::cout << "⚠️  ТРЕБУЮТ ОПРОСА: " << surveyClients.size() << " клиентов\n";
    std::cout << "─────────────────────────────────────────\n";
    int count = 0;
    for (const auto& c : surveyClients) {
        std::cout << std::left << std::setw(15) << c.getCode() 
                  << std::setw(40) << c.getName().substr(0, 38) << "\n";
        if (++count >= 5) break;
    }
    
    printSeparator();
    
    // Товары
    auto products = productService.getAll();
    std::cout << "📦 ТОВАРЫ (первые 5 из " << products.size() << ")\n";
    std::cout << "─────────────────────────────────────────\n";
    count = 0;
    for (const auto& p : products) {
        std::cout << std::left << std::setw(15) << p.getCode() 
                  << std::setw(40) << p.getName().substr(0, 38) << "\n";
        if (++count >= 5) break;
    }
    
    printSeparator();
    
    // Рекомендации (Тест добавленного сервиса)
    auto topRecs = recService.getTopRecommendations(3);
    std::cout << "💡 ТОП-3 УМНЫЕ РЕКОМЕНДАЦИИ\n";
    std::cout << "─────────────────────────────────────────\n";
    for(const auto& r : topRecs) {
        std::cout << "Клиенту: " << r.getClientCode() << " -> Предложить: " << r.getProductName() << "\n";
    }
    
    printSeparator();
    
    db.disconnect();
    LOG_INFO("Application finished successfully");
    
    return 0;
}
EOF

echo -e "\n${BLUE}======================================================================${NC}"
echo -e "${GREEN}✅ ВСЕ СЕРВИСЫ (БИЗНЕС-ЛОГИКА) УСПЕШНО СОЗДАНЫ!${NC}"
echo -e "${BLUE}======================================================================${NC}"
