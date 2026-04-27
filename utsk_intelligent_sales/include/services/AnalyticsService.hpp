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
