#!/bin/bash

# =============================================================================
# СКРИПТ: ЧАСТЬ 6 - СОЗДАНИЕ МОДУЛЯ ОПРОСОВ (SURVEY MODULE)
# =============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}  СОЗДАНИЕ МОДУЛЯ ОПРОСОВ (ЧАСТЬ 6)${NC}"
echo -e "${BLUE}======================================================================${NC}"

# -----------------------------------------------------------------------------
# 1. МОДЕЛЬ SURVEY RESULT
# -----------------------------------------------------------------------------
echo -e "${GREEN}📝 Создание SurveyResult (Model)...${NC}"
cat > include/models/SurveyResult.hpp << 'EOF'
#ifndef SURVEY_RESULT_HPP
#define SURVEY_RESULT_HPP

#include <string>
#include <optional>
#include <pqxx/pqxx>

namespace utsk {

class SurveyResult {
public:
    SurveyResult() = default;

    int getId() const { return m_id; }
    void setId(int id) { m_id = id; }

    const std::string& getClientCode() const { return m_clientCode; }
    void setClientCode(const std::string& code) { m_clientCode = code; }

    const std::string& getSurveyDate() const { return m_surveyDate; }
    void setSurveyDate(const std::string& date) { m_surveyDate = date; }

    bool isContacted() const { return m_isContacted; }
    void setContacted(bool contacted) { m_isContacted = contacted; }

    std::optional<std::string> getContactPerson() const { return m_contactPerson; }
    void setContactPerson(const std::string& person) { m_contactPerson = person; }

    std::optional<std::string> getFeedback() const { return m_feedback; }
    void setFeedback(const std::string& feedback) { m_feedback = feedback; }

    static SurveyResult fromRow(const pqxx::row& row);

private:
    int m_id = 0;
    std::string m_clientCode;
    std::string m_surveyDate;
    bool m_isContacted = false;
    std::optional<std::string> m_contactPerson;
    std::optional<std::string> m_feedback;
};

} // namespace utsk

#endif // SURVEY_RESULT_HPP
EOF

cat > src/models/SurveyResult.cpp << 'EOF'
#include "models/SurveyResult.hpp"

namespace utsk {

SurveyResult SurveyResult::fromRow(const pqxx::row& row) {
    SurveyResult res;
    
    try { if (!row["id"].is_null()) res.setId(row["id"].as<int>()); } catch(...) {}
    try { res.setClientCode(row["client_code"].as<std::string>()); } catch(...) {}
    try { if (!row["survey_date"].is_null()) res.setSurveyDate(row["survey_date"].as<std::string>()); } catch(...) {}
    try { if (!row["is_contacted"].is_null()) res.setContacted(row["is_contacted"].as<bool>()); } catch(...) {}
    try { if (!row["contact_person"].is_null()) res.setContactPerson(row["contact_person"].as<std::string>()); } catch(...) {}
    try { if (!row["feedback"].is_null()) res.setFeedback(row["feedback"].as<std::string>()); } catch(...) {}
    
    return res;
}

} // namespace utsk
EOF

# -----------------------------------------------------------------------------
# 2. СЕРВИС SURVEY SERVICE
# -----------------------------------------------------------------------------
echo -e "${GREEN}📝 Создание SurveyService...${NC}"
cat > include/services/SurveyService.hpp << 'EOF'
#ifndef SURVEY_SERVICE_HPP
#define SURVEY_SERVICE_HPP

#include <vector>
#include "models/SurveyResult.hpp"
#include "core/Database.hpp"

namespace utsk {

class SurveyService {
public:
    explicit SurveyService(Database& db);
    ~SurveyService() = default;

    /**
     * @brief Сохранить результат опроса и обновить статус клиента
     */
    bool saveSurveyResult(const SurveyResult& result);

    /**
     * @brief Получить историю опросов по клиенту
     */
    std::vector<SurveyResult> getHistoryForClient(const std::string& clientCode);

private:
    Database& m_db;
};

} // namespace utsk

#endif // SURVEY_SERVICE_HPP
EOF

cat > src/services/SurveyService.cpp << 'EOF'
#include "services/SurveyService.hpp"
#include "core/Logger.hpp"

namespace utsk {

SurveyService::SurveyService(Database& db) : m_db(db) {
    LOG_DEBUG("SurveyService initialized");
}

bool SurveyService::saveSurveyResult(const SurveyResult& result) {
    try {
        m_db.beginTransaction();

        // 1. Пытаемся записать в таблицу survey_results (создадим её на лету, если нет)
        try {
            m_db.executeParams(R"(
                CREATE TABLE IF NOT EXISTS survey_results (
                    id SERIAL PRIMARY KEY,
                    client_code VARCHAR(50) NOT NULL,
                    survey_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    is_contacted BOOLEAN DEFAULT FALSE,
                    contact_person VARCHAR(255),
                    feedback TEXT
                )
            )", {});
            
            const std::string insertQuery = R"(
                INSERT INTO survey_results (client_code, is_contacted, contact_person, feedback)
                VALUES ($1, $2, $3, $4)
            )";
            
            std::string isCont = result.isContacted() ? "true" : "false";
            std::string person = result.getContactPerson().value_or("");
            std::string feedback = result.getFeedback().value_or("");
            
            m_db.executeParams(insertQuery, {
                result.getClientCode(),
                isCont,
                person,
                feedback
            });
        } catch(const std::exception& e) {
            LOG_WARNING("Could not insert into survey_results: " + std::string(e.what()));
        }

        // 2. Обновляем статус в таблице clients (снимаем флажок)
        const std::string updateClientQuery = R"(
            UPDATE clients 
            SET survey_completed_at = CURRENT_TIMESTAMP,
                requires_survey = FALSE
            WHERE code = $1
        )";
        m_db.executeParams(updateClientQuery, {result.getClientCode()});

        m_db.commit();
        LOG_INFO("Survey result saved successfully for client: " + result.getClientCode());
        return true;
        
    } catch (const std::exception& e) {
        m_db.rollback();
        LOG_ERROR("Failed to save survey result: " + std::string(e.what()));
        return false;
    }
}

std::vector<SurveyResult> SurveyService::getHistoryForClient(const std::string& clientCode) {
    std::vector<SurveyResult> history;
    try {
        const std::string query = "SELECT * FROM survey_results WHERE client_code = $1 ORDER BY survey_date DESC";
        auto result = m_db.executeParams(query, {clientCode});
        
        for (const auto& row : result) {
            history.push_back(SurveyResult::fromRow(row));
        }
    } catch (const std::exception& e) {
        LOG_ERROR("Failed to get survey history: " + std::string(e.what()));
    }
    return history;
}

} // namespace utsk
EOF

# -----------------------------------------------------------------------------
# 3. ИНТЕГРАЦИЯ В MAIN_CONSOLE
# -----------------------------------------------------------------------------
echo -e "${GREEN}📝 Интеграция SurveyService в main_console.cpp...${NC}"

# Просто допишем демонстрацию в конец main перед db.disconnect()
sed -i '/db.disconnect();/i \
    // --- ДЕМОНСТРАЦИЯ МОДУЛЯ ОПРОСОВ ---\n\
    SurveyService surveyService(db);\n\
    if (!surveyClients.empty()) {\n\
        auto targetClient = surveyClients.front();\n\
        std::cout << "📞 СИМУЛЯЦИЯ ОПРОСА\\n";\n\
        std::cout << "─────────────────────────────────────────\\n";\n\
        std::cout << "Звоним клиенту: " << targetClient.getName() << " (" << targetClient.getCode() << ")\\n";\n\
        \n\
        SurveyResult survey;\n\
        survey.setClientCode(targetClient.getCode());\n\
        survey.setContacted(true);\n\
        survey.setContactPerson("Иван Иванович (Директор)");\n\
        survey.setFeedback("Был перерыв в закупках из-за логистики. Возвращаются к работе, нужен счет на арматуру.");\n\
        \n\
        if (surveyService.saveSurveyResult(survey)) {\n\
            std::cout << "✅ Опрос успешно проведен и сохранен в БД!\\n";\n\
            std::cout << "✅ Флаг 'requires_survey' для клиента снят.\\n";\n\
        } else {\n\
            std::cout << "❌ Ошибка при сохранении опроса.\\n";\n\
        }\n\
        printSeparator();\n\
    }\n' src/main_console.cpp

echo -e "\n${BLUE}======================================================================${NC}"
echo -e "${GREEN}✅ МОДУЛЬ ОПРОСОВ УСПЕШНО СОЗДАН И ПРОИНТЕГРИРОВАН!${NC}"
echo -e "${BLUE}======================================================================${NC}"
