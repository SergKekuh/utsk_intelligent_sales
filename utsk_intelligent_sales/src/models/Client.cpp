#include "models/Client.hpp"

namespace utsk {

Client Client::fromRow(const pqxx::row& row) {
    Client client;
    
    // Обязательные поля
    client.setCode(row["code"].as<std::string>());
    client.setName(row["name"].as<std::string>());
    
    // Опциональные поля (проверяем наличие колонки и null)
    try { if (!row["client_type"].is_null()) client.setClientType(row["client_type"].as<std::string>()); } catch(...) {}
    try { if (!row["current_status_id"].is_null()) client.setStatusId(row["current_status_id"].as<int>()); } catch(...) {}
    try { if (!row["status_name"].is_null()) client.setStatusName(row["status_name"].as<std::string>()); } catch(...) {}
    try { if (!row["first_purchase_date"].is_null()) client.setFirstPurchaseDate(row["first_purchase_date"].as<std::string>()); } catch(...) {}
    try { if (!row["last_purchase_date"].is_null()) client.setLastPurchaseDate(row["last_purchase_date"].as<std::string>()); } catch(...) {}
    try { if (!row["activity_direction_id"].is_null()) client.setDirectionId(row["activity_direction_id"].as<int>()); } catch(...) {}
    try { if (!row["direction_name"].is_null()) client.setDirectionName(row["direction_name"].as<std::string>()); } catch(...) {}
    try { if (!row["direction_confidence"].is_null()) client.setDirectionConfidence(row["direction_confidence"].as<double>()); } catch(...) {}
    try { if (!row["requires_survey"].is_null()) client.setRequiresSurvey(row["requires_survey"].as<bool>()); } catch(...) {}
    try { if (!row["total_docs"].is_null()) client.setTotalDocuments(row["total_docs"].as<int>()); } catch(...) {}
    try { if (!row["total_revenue"].is_null()) client.setTotalRevenue(row["total_revenue"].as<double>()); } catch(...) {}
    try { if (!row["days_since_last"].is_null()) client.setDaysSinceLastPurchase(row["days_since_last"].as<int>()); } catch(...) {}
    
    return client;
}

} // namespace utsk
