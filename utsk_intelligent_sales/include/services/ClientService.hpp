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
