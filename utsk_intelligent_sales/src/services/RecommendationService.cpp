#include "services/RecommendationService.hpp"
#include "core/Logger.hpp"
#include <sstream>

namespace utsk {

RecommendationService::RecommendationService(Database& db) : m_db(db) {}

std::vector<Recommendation> RecommendationService::getForClient(const std::string& clientCode) {
    std::vector<Recommendation> recommendations;
    
    const std::string query = R"(
        -- БЛОК 1: История покупок (часто покупаемые товары)
        SELECT 
            c.code as client_code, c.name as client_name,
            p.code as product_code, p.name as product_name,
            'Часто покупаете' as reason, 1 as priority,
            COALESCE(p.in_stock_balance, 0) as in_stock
        FROM clients c
        JOIN documents d ON d.client_code = c.code
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON sl.product_code = p.code
        WHERE c.code = $1 AND COALESCE(p.in_stock_balance, 0) > 0
        GROUP BY c.code, c.name, p.code, p.name, p.in_stock_balance
        HAVING COUNT(sl.id) >= 2
        
        UNION ALL
        
        -- БЛОК 2: Новинки по направлению клиента
        SELECT 
            c.code, c.name, p.code, p.name,
            'Новинка в вашем направлении', 2,
            COALESCE(p.in_stock_balance, 0)
        FROM clients c
        JOIN products p ON c.activity_direction_id = p.anchor_direction_id
        WHERE c.code = $1 AND p.is_new_arrival = TRUE AND COALESCE(p.in_stock_balance, 0) > 0
        
        UNION ALL
        
        -- БЛОК 3: Сопутствующие товары (cross-sells)
        SELECT 
            c.code, c.name, p_related.code, p_related.name,
            'С этим обычно берут', 3,
            COALESCE(p_related.in_stock_balance, 0)
        FROM clients c
        JOIN documents d ON d.client_code = c.code
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN product_cross_sells pcs ON sl.product_code = pcs.main_product_code
        JOIN products p_related ON pcs.related_product_code = p_related.code
        WHERE c.code = $1 AND COALESCE(p_related.in_stock_balance, 0) > 0
        
        ORDER BY priority, in_stock DESC
        LIMIT 5
    )";
    
    try {
        auto result = m_db.executeParams(query, {clientCode});
        
        for (const auto& row : result) {
            Recommendation rec;
            rec.clientCode = row["client_code"].as<std::string>();
            rec.clientName = row["client_name"].as<std::string>();
            rec.productCode = row["product_code"].as<std::string>();
            rec.productName = row["product_name"].as<std::string>();
            rec.reason = row["reason"].as<std::string>();
            rec.priority = row["priority"].as<int>();
            rec.inStockBalance = row["in_stock"].as<double>();
            recommendations.push_back(rec);
        }
        
        // Если рекомендаций нет — предложим популярные товары
        if (recommendations.empty()) {
            const std::string fallbackQuery = R"(
                SELECT 
                    $1 as client_code,
                    (SELECT name FROM clients WHERE code = $1) as client_name,
                    p.code as product_code,
                    p.name as product_name,
                    'Популярный товар' as reason,
                    99 as priority,
                    COALESCE(p.in_stock_balance, 0) as in_stock
                FROM products p
                WHERE COALESCE(p.in_stock_balance, 0) > 0
                ORDER BY p.code
                LIMIT 5
            )";
            
            auto fbResult = m_db.executeParams(fallbackQuery, {clientCode});
            
            for (const auto& row : fbResult) {
                Recommendation rec;
                rec.clientCode = row["client_code"].as<std::string>();
                rec.clientName = row["client_name"].as<std::string>();
                rec.productCode = row["product_code"].as<std::string>();
                rec.productName = row["product_name"].as<std::string>();
                rec.reason = row["reason"].as<std::string>();
                rec.priority = row["priority"].as<int>();
                rec.inStockBalance = row["in_stock"].as<double>();
                recommendations.push_back(rec);
            }
        }
        
        LOG_INFO("Generated " + std::to_string(recommendations.size()) + 
                 " recommendations for client " + clientCode);
        
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Recommendation query failed: ") + e.what());
    }
    
    return recommendations;
}

void RecommendationService::recordAddition(const std::string& clientCode, 
                                            const std::string& productCode) {
    try {
        const std::string query = R"(
            INSERT INTO product_scoring (client_code, product_code, positive_reinforcement)
            VALUES ($1, $2, 5)
            ON CONFLICT (client_code, product_code) 
            DO UPDATE SET 
                positive_reinforcement = product_scoring.positive_reinforcement + 5,
                is_blocked = FALSE,
                blocked_until = NULL,
                updated_at = CURRENT_TIMESTAMP
        )";
        
        m_db.executeParams(query, {clientCode, productCode});
        LOG_INFO("Recorded addition: +5 for product " + productCode);
        
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Failed to record addition: ") + e.what());
    }
}

void RecommendationService::recordRejection(const std::string& clientCode, 
                                             const std::string& productCode) {
    try {
        const std::string query = R"(
            INSERT INTO product_scoring (client_code, product_code, negative_reinforcement)
            VALUES ($1, $2, 3)
            ON CONFLICT (client_code, product_code) 
            DO UPDATE SET 
                negative_reinforcement = product_scoring.negative_reinforcement + 3,
                updated_at = CURRENT_TIMESTAMP
        )";
        
        m_db.executeParams(query, {clientCode, productCode});
        
        const std::string blockQuery = R"(
            UPDATE product_scoring 
            SET is_blocked = TRUE,
                blocked_until = CURRENT_DATE + INTERVAL '30 days'
            WHERE client_code = $1 
              AND product_code = $2 
              AND current_weight < 0
        )";
        
        m_db.executeParams(blockQuery, {clientCode, productCode});
        
        const std::string logQuery = R"(
            INSERT INTO manager_rejections_log (client_code, product_code, reject_reason)
            VALUES ($1, $2, 'Отклонено менеджером')
        )";
        
        m_db.executeParams(logQuery, {clientCode, productCode});
        
        LOG_INFO("Recorded rejection: -3 for product " + productCode);
        
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Failed to record rejection: ") + e.what());
    }
}

std::vector<std::pair<std::string, std::string>> RecommendationService::getClientList() {
    std::vector<std::pair<std::string, std::string>> clients;
    
    const std::string query = R"(
        SELECT code, name 
        FROM clients 
        ORDER BY name
        LIMIT 50
    )";
    
    try {
        auto result = m_db.execute(query);
        
        for (const auto& row : result) {
            clients.push_back({
                row["code"].as<std::string>(),
                row["name"].as<std::string>()
            });
        }
        
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Failed to get client list: ") + e.what());
    }
    
    return clients;
}

} // namespace utsk
