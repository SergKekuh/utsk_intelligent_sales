#include <gtest/gtest.h>
#include <string>
#include <cstdlib>
#include <stdexcept>
#include "core/Database.hpp"
#include "core/Config.hpp"

using namespace utsk;

class DatabaseTest : public ::testing::Test {
protected:
    Config config;
    Database::ConnectionInfo dbInfo;

    void SetUp() override {
        // 1. Умная загрузка конфигурации
        if (!config.load("config/db_config.json") && 
            !config.load("../config/db_config.json") && 
            !config.load("../../config/db_config.json")) {
            
            // Если файла нет (как в GitHub Actions), берем из переменных окружения
            const char* env_host = std::getenv("PGHOST");
            const char* env_user = std::getenv("PGUSER");
            const char* env_pass = std::getenv("PGPASSWORD");
            
            dbInfo.host     = env_host ? env_host : "localhost";
            dbInfo.port     = 5432;  // ✅ int, не const char*
            dbInfo.dbname   = "bd_intelligent_sales";
            dbInfo.user     = env_user ? env_user : "postgres";
            dbInfo.password = env_pass ? env_pass : "root";
        } else {
            dbInfo = config.getDatabaseInfo();
        }
        
        // 2. Подготавливаем базу данных
        Database db;
        if (db.connect(dbInfo)) {
            db.execute(R"(
                CREATE TABLE IF NOT EXISTS clients (
                    code VARCHAR(50) PRIMARY KEY,
                    name VARCHAR(255) NOT NULL DEFAULT 'Test'
                )
            )");
            db.execute("INSERT INTO clients (code, name) VALUES ('36', 'Test Client') ON CONFLICT DO NOTHING");
            db.disconnect();
        }
    }
};

TEST_F(DatabaseTest, ConnectSuccess) {
    Database db;
    EXPECT_TRUE(db.connect(dbInfo));
    EXPECT_TRUE(db.isConnected());
    db.disconnect();
}

TEST_F(DatabaseTest, DisconnectWorks) {
    Database db;
    db.connect(dbInfo);
    db.disconnect();
    EXPECT_FALSE(db.isConnected());
}

TEST_F(DatabaseTest, ExecuteQueryReturnsData) {
    Database db;
    ASSERT_TRUE(db.connect(dbInfo));
    auto result = db.execute("SELECT COUNT(*) as cnt FROM clients");
    EXPECT_GT(result.size(), 0);
    db.disconnect();
}

TEST_F(DatabaseTest, ExecuteQueryThrowsOnError) {
    Database db;
    ASSERT_TRUE(db.connect(dbInfo));
    EXPECT_THROW(db.execute("SELECT * FROM nonexistent_table"), std::exception);
    db.disconnect();
}

TEST_F(DatabaseTest, ExecuteParamsWorks) {
    Database db;
    ASSERT_TRUE(db.connect(dbInfo));
    auto result = db.executeParams("SELECT * FROM clients WHERE code = $1", {"36"});
    EXPECT_GT(result.size(), 0);
    db.disconnect();
}

TEST_F(DatabaseTest, ExecuteWithoutConnectionThrows) {
    Database db;
    EXPECT_FALSE(db.isConnected());
    EXPECT_THROW(db.execute("SELECT 1"), std::exception);
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
