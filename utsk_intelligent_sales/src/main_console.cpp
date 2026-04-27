#include "core/Config.hpp"
#include "core/Logger.hpp"
#include "core/Database.hpp"
#include "services/ClientService.hpp"
#include "services/ProductService.hpp"
#include "services/RecommendationService.hpp"
#include "ui/ConsoleUI.hpp"
#include <iostream>

using namespace utsk;

int main() {
    Logger::getInstance().init("", Logger::Level::INFO);
    
    LOG_INFO("UTSK Intelligent Sales - Console v1.0.0");
    
    Config config;
    if (!config.load("config/db_config.json")) {
        std::cerr << "Failed to load config/db_config.json!" << std::endl;
        return 1;
    }
    
    // Подключение к БД (типы уже совпадают!)
    Database db;
    if (!db.connect(config.getDatabaseInfo())) {
        std::cerr << "Failed to connect to database!" << std::endl;
        return 1;
    }
    
    ClientService clientService(db);
    ProductService productService(db);
    RecommendationService recService(db);
    
    ConsoleUI ui(db, clientService, productService, recService);
    ui.run();
    
    db.disconnect();
    LOG_INFO("Application finished");
    
    return 0;
}
