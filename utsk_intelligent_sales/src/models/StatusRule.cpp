#include "models/StatusRule.hpp"

namespace utsk {

StatusRule StatusRule::fromRow(const pqxx::row& row) {
    StatusRule rule;
    
    rule.setId(row["id"].as<int>());
    rule.setStatusName(row["status_name"].as<std::string>());
    rule.setPriority(row["priority"].as<int>());
    
    return rule;
}

} // namespace utsk
