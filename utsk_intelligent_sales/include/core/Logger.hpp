#ifndef LOGGER_HPP
#define LOGGER_HPP

#include <string>
#include <fstream>
#include <mutex>

namespace utsk {

class Logger {
public:
    enum class Level {
        DEBUG,
        INFO,
        WARNING,
        ERROR
    };

    static Logger& getInstance();

    void init(const std::string& logFile = "", Level level = Level::INFO);
    void log(Level level, const std::string& message);

    void debug(const std::string& msg)   { log(Level::DEBUG, msg); }
    void info(const std::string& msg)    { log(Level::INFO, msg); }
    void warning(const std::string& msg) { log(Level::WARNING, msg); }
    void error(const std::string& msg)   { log(Level::ERROR, msg); }

    void setLevel(Level level) { m_level = level; }
    void setUseColors(bool use) { m_useColors = use; }

private:
    Logger();
    ~Logger();
    Logger(const Logger&) = delete;
    Logger& operator=(const Logger&) = delete;

    std::string levelToString(Level level);
    std::string getTimestamp();
    std::string colorize(Level level, const std::string& text);

    std::ofstream m_file;
    Level m_level = Level::INFO;
    bool m_useColors = true;
    bool m_initialized = false;
    std::mutex m_mutex;
};

} // namespace utsk

#define LOG_DEBUG(msg)   utsk::Logger::getInstance().debug(msg)
#define LOG_INFO(msg)    utsk::Logger::getInstance().info(msg)
#define LOG_WARNING(msg) utsk::Logger::getInstance().warning(msg)
#define LOG_ERROR(msg)   utsk::Logger::getInstance().error(msg)

#endif // LOGGER_HPP
