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
