#ifndef CONSOLE_UI_HPP
#define CONSOLE_UI_HPP

#include "core/Database.hpp"
#include "services/ClientService.hpp"
#include "services/ProductService.hpp"
#include "services/RecommendationService.hpp"
#include "ui/ConsoleMenu.hpp"
#include "ui/TablePrinter.hpp"

namespace utsk {

class ConsoleUI {
public:
    ConsoleUI(Database& db, ClientService& clientSvc, ProductService& productSvc, RecommendationService& recSvc);
    void run();

private:
    void showDashboard();
    void showProducts();
    void showStatusDistribution();
    void showDirectionDistribution();
    void showRequiringSurvey();
    void showClientList();
    void showRecommendations(const std::string& clientCode);
    void waitForKey();

    Database& m_db;
    ClientService& m_clientService;
    ProductService& m_productService;
    RecommendationService& m_recService;
    ConsoleMenu m_menu;
};

} // namespace utsk

#endif
