#include "core/Logger.hpp"
#include <iostream>
#include <chrono>
#include <iomanip>
#include <ctime>

namespace utsk {

namespace Color {
    const std::string RESET   = "\033[0m";
    const std::string RED     = "\033[31m";
    const std::string GREEN   = "\033[32m";
    const std::string YELLOW  = "\033[33m";
    const std::string CYAN    = "\033[36m";
    const std::string BOLD    = "\033[1m";
}

Logger& Logger::getInstance() {
    static Logger instance;
    return instance;
}

Logger::Logger() = default;

Logger::~Logger() {
    if (m_file.is_open()) {
        m_file.close();
    }
}

void Logger::init(const std::string& logFile, Level level) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_level = level;
    
    if (!logFile.empty()) {
        m_file.open(logFile, std::ios::out | std::ios::app);
    }
    
    m_initialized = true;
}

void Logger::log(Level level, const std::string& message) {
    if (level < m_level) return;
    
    std::lock_guard<std::mutex> lock(m_mutex);
    
    std::string timestamp = getTimestamp();
    std::string levelStr = levelToString(level);
    std::string fullMessage = "[" + timestamp + "] [" + levelStr + "] " + message;
    
    if (m_useColors) {
        std::cout << colorize(level, fullMessage) << std::endl;
    } else {
        std::cout << fullMessage << std::endl;
    }
    
    if (m_file.is_open()) {
        m_file << fullMessage << std::endl;
        m_file.flush();
    }
}

std::string Logger::levelToString(Level level) {
    switch (level) {
        case Level::DEBUG:   return "DEBUG";
        case Level::INFO:    return "INFO ";
        case Level::WARNING: return "WARN ";
        case Level::ERROR:   return "ERROR";
        default:             return "???? ";
    }
}

std::string Logger::getTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
        now.time_since_epoch()) % 1000;
    
    std::stringstream ss;
    ss << std::put_time(std::localtime(&time_t), "%Y-%m-%d %H:%M:%S");
    ss << "." << std::setfill('0') << std::setw(3) << ms.count();
    return ss.str();
}

std::string Logger::colorize(Level level, const std::string& text) {
    switch (level) {
        case Level::DEBUG:   return Color::CYAN + text + Color::RESET;
        case Level::INFO:    return Color::GREEN + text + Color::RESET;
        case Level::WARNING: return Color::YELLOW + Color::BOLD + text + Color::RESET;
        case Level::ERROR:   return Color::RED + Color::BOLD + text + Color::RESET;
        default:             return text;
    }
}

} // namespace utsk
