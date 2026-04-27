#ifndef ACTIVITY_DIRECTION_HPP
#define ACTIVITY_DIRECTION_HPP

#include <string>
#include <optional>
#include <pqxx/pqxx>

namespace utsk {

class ActivityDirection {
public:
    ActivityDirection() = default;

    int getId() const { return m_id; }
    void setId(int id) { m_id = id; }

    const std::string& getName() const { return m_name; }
    void setName(const std::string& name) { m_name = name; }

    std::optional<std::string> getDescription() const { return m_description; }
    void setDescription(const std::string& desc) { m_description = desc; }

    static ActivityDirection fromRow(const pqxx::row& row);

private:
    int m_id = 0;
    std::string m_name;
    std::optional<std::string> m_description;
};

} // namespace utsk

#endif // ACTIVITY_DIRECTION_HPP
