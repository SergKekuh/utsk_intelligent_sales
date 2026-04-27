#include "core/Database.hpp"
#include "core/Logger.hpp"
#include <stdexcept>

namespace utsk {

Database::Database() : m_connected(false) {
    LOG_DEBUG("Database instance created");
}

Database::~Database() {
    disconnect();
}

bool Database::connect(const ConnectionInfo& info) {
    try {
        std::string conn_str = "host=" + info.host + 
                               " port=" + std::to_string(info.port) + 
                               " dbname=" + info.dbname + 
                               " user=" + info.user;
        
        if (!info.password.empty()) {
            conn_str += " password=" + info.password;
        }

        LOG_INFO("Connecting to database: " + info.dbname + "@" + info.host);
        
        m_connection = std::make_unique<pqxx::connection>(conn_str);
        
        if (m_connection->is_open()) {
            m_connected = true;
            LOG_INFO("Connected to database successfully");
            return true;
        } else {
            m_connected = false;
            LOG_ERROR("Failed to open database connection");
            return false;
        }
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Database connection error: ") + e.what());
        m_connected = false;
        return false;
    }
}

void Database::disconnect() {
    if (m_connection && m_connection->is_open()) {
        LOG_INFO("Disconnecting from database");
        m_connection->close();
    }
    m_connected = false;
}

bool Database::isConnected() const {
    return m_connected && m_connection && m_connection->is_open();
}

pqxx::result Database::execute(const std::string& query) {
    if (!isConnected()) {
        throw std::runtime_error("Not connected to database");
    }

    try {
        LOG_DEBUG("Executing query: " + query.substr(0, 100) + (query.size() > 100 ? "..." : ""));
        
        pqxx::work w(*m_connection);
        pqxx::result res = w.exec(query);
        w.commit();
        
        LOG_DEBUG("Query returned " + std::to_string(res.size()) + " rows");
        return res;
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Query execution error: ") + e.what());
        throw;
    }
}

pqxx::result Database::executeParams(const std::string& query, 
                                      const std::vector<std::string>& params) {
    if (!isConnected()) {
        throw std::runtime_error("Not connected to database");
    }

    try {
        LOG_DEBUG("Executing parameterized query");
        
        pqxx::work w(*m_connection);
        
        // УНИВЕРСАЛЬНЫЙ СПОСОБ — работает в libpqxx 7.8 и 7.10+
        // Преобразуем vector<string> → vector<const char*>
        std::vector<const char*> c_params;
        c_params.reserve(params.size());
        for (const auto& p : params) {
            c_params.push_back(p.c_str());
        }
        
        pqxx::result res;
        switch (c_params.size()) {
            case 1:
                res = w.exec_params(query, c_params[0]);
                break;
            case 2:
                res = w.exec_params(query, c_params[0], c_params[1]);
                break;
            case 3:
                res = w.exec_params(query, c_params[0], c_params[1], c_params[2]);
                break;
            case 4:
                res = w.exec_params(query, c_params[0], c_params[1], c_params[2], c_params[3]);
                break;
            case 5:
                res = w.exec_params(query, c_params[0], c_params[1], c_params[2], c_params[3], c_params[4]);
                break;
            default:
                throw std::runtime_error("Too many parameters (max 5)");
        }
        
        w.commit();
        
        LOG_DEBUG("Query returned " + std::to_string(res.size()) + " rows");
        return res;
    } catch (const std::exception& e) {
        LOG_ERROR(std::string("Parameterized query error: ") + e.what());
        throw;
    }
}

void Database::beginTransaction() {
    if (!m_transaction && isConnected()) {
        LOG_DEBUG("Beginning transaction");
        m_transaction = std::make_unique<pqxx::work>(*m_connection);
    }
}

void Database::commit() {
    if (m_transaction) {
        LOG_DEBUG("Committing transaction");
        m_transaction->commit();
        m_transaction.reset();
    }
}

void Database::rollback() {
    if (m_transaction) {
        LOG_WARNING("Rolling back transaction");
        m_transaction->abort();
        m_transaction.reset();
    }
}

} // namespace utsk
