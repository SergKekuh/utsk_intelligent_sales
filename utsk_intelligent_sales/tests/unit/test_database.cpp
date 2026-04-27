#include <gtest/gtest.h>
#include <string>
#include "core/Database.hpp"
#include "core/Config.hpp"

using namespace utsk;

class DatabaseTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Загрузка конфига
        config.load("config/db_config.json");
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
    EXPECT_GT(result[0][0].as<int>(), 0);
    
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
    EXPECT_EQ(result[0]["code"].as<std::string>(), "36");
    
    db.disconnect();
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}

TEST_F(DatabaseTest, ExecuteWithoutConnectionThrows) {
    Database db;
    // НЕ вызываем connect() — базы нет
    EXPECT_FALSE(db.isConnected());
    EXPECT_THROW(db.execute("SELECT 1"), std::runtime_error);
}
