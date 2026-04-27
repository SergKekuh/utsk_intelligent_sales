#include "ui/ConsoleUI.hpp"
#include <iomanip>
#include <iostream>
#include <sstream>

namespace utsk {

ConsoleUI::ConsoleUI(Database &db, ClientService &clientSvc,
                     ProductService &productSvc, RecommendationService &recSvc)
    : m_db(db), m_clientService(clientSvc), m_productService(productSvc),
      m_recService(recSvc) {

  m_menu.setTitle("UTSK INTELLIGENT SALES v1.0.0");

  m_menu.addItem("1", "📊 Дашборд", [this]() { showDashboard(); });
  m_menu.addItem("2", "👥 Клиенты (требуют опроса)",
                 [this]() { showRequiringSurvey(); });
  m_menu.addItem("3", "🏷️  Статусы клиентов",
                 [this]() { showStatusDistribution(); });
  m_menu.addItem("4", "🎯 Направления деятельности",
                 [this]() { showDirectionDistribution(); });
  m_menu.addItem("5", "📦 Товары", [this]() { showProducts(); });
  m_menu.addItem("6", "💡 Рекомендации для клиента",
                 [this]() { showClientList(); });
  m_menu.addSeparator();
  m_menu.addItem("0", "🚪 Выход", [this]() { m_menu.exit(); });
}

void ConsoleUI::run() { m_menu.run(); }

void ConsoleUI::waitForKey() {
  std::cout << "\nНажмите Enter для продолжения...";
  std::string dummy;
  std::getline(std::cin, dummy);
}

void ConsoleUI::showDashboard() {
  auto stats = m_clientService.getDashboardStats();

  TablePrinter table;
  table.setTitle("📊 ДАШБОРД");
  table.addColumn("Показатель", 30);
  table.addColumn("Значение", 25, TablePrinter::Alignment::Right);
  table.addRow({"Всего клиентов", std::to_string(stats.totalClients)});
  table.addRow({"Активных (30 дней)", std::to_string(stats.active30Days)});
  table.addRow({"Активных (90 дней)", std::to_string(stats.active90Days)});

  std::stringstream ss;
  ss << std::fixed << std::setprecision(2) << stats.totalRevenue << " грн";
  table.addRow({"Общая выручка", ss.str()});

  table.print();
  waitForKey();
}

void ConsoleUI::showRequiringSurvey() {
  auto clients = m_clientService.getRequiringSurvey();

  TablePrinter table;
  table.setTitle("⚠️  КЛИЕНТЫ, ТРЕБУЮЩИЕ ОПРОСА (" +
                 std::to_string(clients.size()) + ")");
  table.addColumn("Код", 12);
  table.addColumn("Название", 40);
  table.addColumn("Тип", 18);
  table.addColumn("Статус", 16);

  for (const auto &c : clients) {
    std::vector<std::string> row;
    row.push_back(c.getCode());
    row.push_back(c.getName());
    row.push_back(c.getClientType().value_or("-"));
    row.push_back(c.getStatusName().value_or("-"));
    table.addRow(row);
  }
  table.print();
  waitForKey();
}

void ConsoleUI::showStatusDistribution() {
  auto stats = m_clientService.getStatusDistribution();

  TablePrinter table;
  table.setTitle("🏷️  РАСПРЕДЕЛЕНИЕ ПО СТАТУСАМ");
  table.addColumn("Статус", 22);
  table.addColumn("Количество", 12, TablePrinter::Alignment::Right);
  table.addColumn("%", 10, TablePrinter::Alignment::Right);

  for (const auto &s : stats) {
    std::stringstream ss;
    ss << std::fixed << std::setprecision(1) << s.percentage;
    std::vector<std::string> row;
    row.push_back(s.statusName);
    row.push_back(std::to_string(s.count));
    row.push_back(ss.str() + "%");
    table.addRow(row);
  }
  table.print();
  waitForKey();
}

void ConsoleUI::showDirectionDistribution() {
  auto stats = m_clientService.getDirectionDistribution();

  TablePrinter table;
  table.setTitle("🎯 РАСПРЕДЕЛЕНИЕ ПО НАПРАВЛЕНИЯМ");
  table.addColumn("Направление", 32);
  table.addColumn("Количество", 12, TablePrinter::Alignment::Right);
  table.addColumn("%", 10, TablePrinter::Alignment::Right);

  for (const auto &d : stats) {
    std::stringstream ss;
    ss << std::fixed << std::setprecision(1) << d.percentage;
    std::vector<std::string> row;
    row.push_back(d.directionName);
    row.push_back(std::to_string(d.count));
    row.push_back(ss.str() + "%");
    table.addRow(row);
  }
  table.print();
  waitForKey();
}

void ConsoleUI::showProducts() {
  auto products = m_productService.getAll();

  TablePrinter table;
  table.setTitle("📦 ТОВАРЫ (первые 20)");
  table.addColumn("Код", 12);
  table.addColumn("Название", 45);
  table.addColumn("Направление", 22);

  int count = 0;
  for (const auto &p : products) {
    std::vector<std::string> row;
    row.push_back(p.getCode());
    row.push_back(p.getName().substr(0, 43));
    row.push_back(p.getDirectionName().value_or("-"));
    table.addRow(row);
    if (++count >= 20)
      break;
  }
  table.print();
  waitForKey();
}

void ConsoleUI::showClientList() {
  auto clients = m_recService.getClientList();

  TablePrinter table;
  table.setTitle("👥 ВЫБЕРИТЕ КЛИЕНТА ДЛЯ РЕКОМЕНДАЦИЙ");
  table.addColumn("Код", 12);
  table.addColumn("Название", 50);

  for (const auto &[code, name] : clients) {
    std::vector<std::string> row;
    row.push_back(code);
    row.push_back(name);
    table.addRow(row);
  }
  table.print();

  std::cout << "\nВведите код клиента (или 0 для выхода): ";
  std::string code;
  std::getline(std::cin, code);

  if (code != "0" && !code.empty()) {
    showRecommendations(code);
  }
}

void ConsoleUI::showRecommendations(const std::string &clientCode) {
  auto recs = m_recService.getForClient(clientCode);

  if (recs.empty()) {
    std::cout << "\nНет рекомендаций для данного клиента.\n";
    waitForKey();
    return;
  }

  TablePrinter table;
  table.setTitle("💡 РЕКОМЕНДАЦИИ ДЛЯ КЛИЕНТА: " + recs[0].clientName);
  table.addColumn("#", 3, TablePrinter::Alignment::Center);
  table.addColumn("Код товара", 12);
  table.addColumn("Название", 60);
  table.addColumn("Причина", 30);
  table.addColumn("На складе", 10, TablePrinter::Alignment::Right);

  int index = 1;
  for (const auto &rec : recs) {
    std::stringstream stock;
    stock << std::fixed << std::setprecision(1) << rec.inStockBalance;
    std::vector<std::string> row;
    row.push_back(std::to_string(index++));
    row.push_back(rec.productCode);
    row.push_back(rec.productName);
    row.push_back(rec.reason);
    row.push_back(stock.str());
    table.addRow(row);
  }
  table.print();
  waitForKey();
}

} // namespace utsk
