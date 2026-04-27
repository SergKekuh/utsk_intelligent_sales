#ifndef STATUS_RULE_HPP
#define STATUS_RULE_HPP

#include <string>
#include <pqxx/pqxx>

namespace utsk {

class StatusRule {
public:
    StatusRule() = default;

    int getId() const { return m_id; }
    void setId(int id) { m_id = id; }

    const std::string& getStatusName() const { return m_statusName; }
    void setStatusName(const std::string& name) { m_statusName = name; }

    int getPriority() const { return m_priority; }
    void setPriority(int priority) { m_priority = priority; }

    static StatusRule fromRow(const pqxx::row& row);

private:
    int m_id = 0;
    std::string m_statusName;
    int m_priority = 0;
};

} // namespace utsk

#endif // STATUS_RULE_HPP
