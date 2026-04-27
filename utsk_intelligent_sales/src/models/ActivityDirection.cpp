#include "models/ActivityDirection.hpp"

namespace utsk {

ActivityDirection ActivityDirection::fromRow(const pqxx::row& row) {
    ActivityDirection dir;
    
    dir.setId(row["id"].as<int>());
    dir.setName(row["name"].as<std::string>());
    
    try { if (!row["description"].is_null()) dir.setDescription(row["description"].as<std::string>()); } catch(...) {}
    
    return dir;
}

} // namespace utsk
