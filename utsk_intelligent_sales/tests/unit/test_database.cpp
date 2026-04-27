#include <gtest/gtest.h>
#include <string>
#include <cstdlib>
#include "core/Database.hpp"
#include "core/Config.hpp"

using namespace utsk;

class DatabaseTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Пробуем загрузить конфиг из файла
        if (!config.load("config/db_config.json")) {
            // Если файла нет — берём из переменных окружения
            const char* env_host = std::getenv("PGHOST");
            const char* env_port = std::getenv("PGPORT");
            const char* env_db   = std::getenv("PGDATABASE");
            const char* env_user = std::getenv("PGUSER");
            const char* env_pass = std::getenv("PGPASSWORD");
            
            Database::ConnectionInfo dbInfo;
            dbInfo.host     = env_host ? env_host : "localhost";
            dbInfo.port     = env_port ? std::stoi(env_port) : 5432;
            dbInfo.dbname   = env_db   ? env_db   : "bd_intelligent_sales";
            dbInfo.user     = env_user ? env_user : "postgres";
            dbInfo.password = env_pass ? env_pass : "root";
            
            config.setDatabaseInfo(dbInfo);
        }
    }
    
    Config config;
};

TEST_F(DatabaseTest, ConnectSuccess) {
    Database db;
    EXPECT_TRUE(db.connect(config.getDatabaseInfo()));
    EXPECT_TRUE(db.isConnected());
    db.disconnect();
}

TEST_F(DatabaseTest, DisconnectWorks) {
    Database db;
    db.connect(config.getDatabaseInfo());
    db.disconnect();
    EXPECT_FALSE(db.isConnected());
}

TEST_F(DatabaseTest, ExecuteQueryReturnsData) {
    Database db;
    db.connect(config.getDatabaseInfo());
    auto result = db.execute("SELECT COUNT(*) FROM clients");
    EXPECT_GT(result.size(), 0);
    db.disconnect();
}

TEST_F(DatabaseTest, ExecuteQueryThrowsOnError) {
    Database db;
    db.connect(config.getDatabaseInfo());
    EXPECT_THROW(db.execute("SELECT * FROM nonexistent_table"), std::exception);
    db.disconnect();
}

TEST_F(DatabaseTest, ExecuteParamsWorks) {
    Database db;
    db.connect(config.getDatabaseInfo());
    auto result = db.executeParams("SELECT * FROM clients WHERE code = $1", {"36"});
    EXPECT_GT(result.size(), 0);
    db.disconnect();
}

TEST_F(DatabaseTest, ExecuteWithoutConnectionThrows) {
    Database db;
    EXPECT_FALSE(db.isConnected());
    EXPECT_THROW(db.execute("SELECT 1"), std::runtime_error);
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
