#include "core/Config.hpp"
#include <fstream>
#include <iostream>
#include <nlohmann/json.hpp>

namespace utsk {

bool Config::load(const std::string& filepath) {
    try {
        std::ifstream file(filepath);
        if (!file.is_open()) {
            std::cerr << "[Config] ERROR: Cannot open file: " << filepath << std::endl;
            return false;
        }

        nlohmann::json json;
        file >> json;

        if (json.contains("database")) {
            auto& db = json["database"];
            m_dbInfo.host = db.value("host", "localhost");
            m_dbInfo.port = db.value("port", 5432);
            m_dbInfo.dbname = db.value("dbname", "bd_intelligent_sales");
            m_dbInfo.user = db.value("user", "postgres");
            m_dbInfo.password = db.value("password", "");
        }

        if (json.contains("app")) {
            auto& app = json["app"];
            m_logLevel = app.value("log_level", "info");
            m_logFile = app.value("log_file", "utsk.log");
        }

        std::cout << "[Config] Loaded: " << filepath << std::endl;
        return true;

    } catch (const std::exception& e) {
        std::cerr << "[Config] ERROR: " << e.what() << std::endl;
        return false;
    }
}

bool Config::save(const std::string& filepath) {
    try {
        nlohmann::json json;
        json["database"] = {
            {"host", m_dbInfo.host},
            {"port", m_dbInfo.port},
            {"dbname", m_dbInfo.dbname},
            {"user", m_dbInfo.user},
            {"password", m_dbInfo.password}
        };
        json["app"] = {
            {"log_level", m_logLevel},
            {"log_file", m_logFile}
        };

        std::ofstream file(filepath);
        file << json.dump(4);
        return true;

    } catch (const std::exception& e) {
        std::cerr << "[Config] ERROR: " << e.what() << std::endl;
        return false;
    }
}

} // namespace utsk
