#ifndef CLIENT_HPP
#define CLIENT_HPP

#include <string>
#include <optional>
#include <pqxx/pqxx>

namespace utsk {

/**
 * @brief Модель клиента (таблица clients)
 */
class Client {
public:
    Client() = default;

    // Геттеры и сеттеры
    const std::string& getCode() const { return m_code; }
    void setCode(const std::string& code) { m_code = code; }

    const std::string& getName() const { return m_name; }
    void setName(const std::string& name) { m_name = name; }

    std::optional<std::string> getClientType() const { return m_clientType; }
    void setClientType(const std::string& type) { m_clientType = type; }

    std::optional<int> getStatusId() const { return m_statusId; }
    void setStatusId(int id) { m_statusId = id; }

    std::optional<std::string> getStatusName() const { return m_statusName; }
    void setStatusName(const std::string& name) { m_statusName = name; }

    std::optional<std::string> getFirstPurchaseDate() const { return m_firstPurchase; }
    void setFirstPurchaseDate(const std::string& date) { m_firstPurchase = date; }

    std::optional<std::string> getLastPurchaseDate() const { return m_lastPurchase; }
    void setLastPurchaseDate(const std::string& date) { m_lastPurchase = date; }

    std::optional<int> getDirectionId() const { return m_directionId; }
    void setDirectionId(int id) { m_directionId = id; }

    std::optional<std::string> getDirectionName() const { return m_directionName; }
    void setDirectionName(const std::string& name) { m_directionName = name; }

    std::optional<double> getDirectionConfidence() const { return m_confidence; }
    void setDirectionConfidence(double conf) { m_confidence = conf; }

    bool requiresSurvey() const { return m_requiresSurvey; }
    void setRequiresSurvey(bool required) { m_requiresSurvey = required; }

    int getTotalDocuments() const { return m_totalDocuments; }
    void setTotalDocuments(int count) { m_totalDocuments = count; }

    double getTotalRevenue() const { return m_totalRevenue; }
    void setTotalRevenue(double revenue) { m_totalRevenue = revenue; }

    int getDaysSinceLastPurchase() const { return m_daysSinceLast; }
    void setDaysSinceLastPurchase(int days) { m_daysSinceLast = days; }

    /**
     * @brief Создать объект Client из строки результата запроса
     * @param row Строка из pqxx::result
     * @return Объект Client
     */
    static Client fromRow(const pqxx::row& row);

private:
    std::string m_code;
    std::string m_name;
    std::optional<std::string> m_clientType;
    std::optional<int> m_statusId;
    std::optional<std::string> m_statusName;
    std::optional<std::string> m_firstPurchase;
    std::optional<std::string> m_lastPurchase;
    std::optional<int> m_directionId;
    std::optional<std::string> m_directionName;
    std::optional<double> m_confidence;
    bool m_requiresSurvey = false;
    int m_totalDocuments = 0;
    double m_totalRevenue = 0.0;
    int m_daysSinceLast = 0;
};

} // namespace utsk

#endif // CLIENT_HPP
