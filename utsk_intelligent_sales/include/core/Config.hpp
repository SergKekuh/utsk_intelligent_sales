#ifndef CONFIG_HPP
#define CONFIG_HPP

#include <string>
#include "Database.hpp"

namespace utsk {

class Config {
public:
    Config() = default;
    ~Config() = default;

    bool load(const std::string& filepath);
    bool save(const std::string& filepath);

    // ИСПОЛЬЗУЕМ Database::ConnectionInfo
    const Database::ConnectionInfo& getDatabaseInfo() const { return m_dbInfo; }
    void setDatabaseInfo(const Database::ConnectionInfo& info) { m_dbInfo = info; }

    const std::string& getLogLevel() const { return m_logLevel; }
    void setLogLevel(const std::string& level) { m_logLevel = level; }

    const std::string& getLogFile() const { return m_logFile; }
    void setLogFile(const std::string& file) { m_logFile = file; }

private:
    Database::ConnectionInfo m_dbInfo;  // ЕДИНЫЙ ТИП
    std::string m_logLevel = "info";
    std::string m_logFile = "utsk.log";
};

} // namespace utsk

#endif
