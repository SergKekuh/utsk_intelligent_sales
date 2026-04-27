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
