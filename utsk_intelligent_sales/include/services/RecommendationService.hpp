#ifndef RECOMMENDATION_SERVICE_HPP
#define RECOMMENDATION_SERVICE_HPP

#include <vector>
#include <string>
#include "core/Database.hpp"

namespace utsk {

/**
 * @brief Модель рекомендации
 */
struct Recommendation {
    std::string clientCode;
    std::string clientName;
    std::string productCode;
    std::string productName;
    std::string reason;
    int priority;
    double inStockBalance;
};

/**
 * @brief Сервис умных рекомендаций товаров
 */
class RecommendationService {
public:
    explicit RecommendationService(Database& db);
    ~RecommendationService() = default;

    std::vector<Recommendation> getForClient(const std::string& clientCode);
    void recordAddition(const std::string& clientCode, const std::string& productCode);
    void recordRejection(const std::string& clientCode, const std::string& productCode);
    std::vector<std::pair<std::string, std::string>> getClientList();

private:
    Database& m_db;
};

} // namespace utsk

#endif // RECOMMENDATION_SERVICE_HPP
