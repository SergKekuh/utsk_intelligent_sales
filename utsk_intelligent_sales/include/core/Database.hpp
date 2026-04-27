#ifndef DATABASE_HPP
#define DATABASE_HPP

#include <pqxx/pqxx>
#include <memory>
#include <string>
#include <vector>

namespace utsk {

/**
 * @brief Класс для работы с PostgreSQL через libpqxx
 */
class Database {
public:
    struct ConnectionInfo {
        std::string host = "localhost";
        int port = 5432;
        std::string dbname;
        std::string user;
        std::string password;
    };

    Database();
    ~Database();

    /**
     * @brief Подключиться к базе данных
     * @param info Параметры подключения
     * @return true если успешно
     */
    bool connect(const ConnectionInfo& info);

    /**
     * @brief Отключиться от базы данных
     */
    void disconnect();

    /**
     * @brief Проверить состояние подключения
     */
    bool isConnected() const;

    /**
     * @brief Выполнить SQL-запрос без параметров
     * @param query SQL-запрос
     * @return Результат запроса
     */
    pqxx::result execute(const std::string& query);

    /**
     * @brief Выполнить SQL-запрос с параметрами (защита от инъекций)
     * @param query SQL-запрос с плейсхолдерами $1, $2, ...
     * @param params Вектор параметров
     * @return Результат запроса
     */
    pqxx::result executeParams(const std::string& query, 
                                const std::vector<std::string>& params);

    /**
     * @brief Начать транзакцию
     */
    void beginTransaction();

    /**
     * @brief Зафиксировать транзакцию
     */
    void commit();

    /**
     * @brief Откатить транзакцию
     */
    void rollback();

private:
    std::unique_ptr<pqxx::connection> m_connection;
    std::unique_ptr<pqxx::work> m_transaction;
    bool m_connected;
};

} // namespace utsk

#endif // DATABASE_HPP
