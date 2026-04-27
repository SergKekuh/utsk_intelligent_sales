#include "services/ProductService.hpp"
#include "core/Logger.hpp"

namespace utsk {

ProductService::ProductService(Database& db) : m_db(db) {
    LOG_DEBUG("ProductService initialized");
}

std::vector<Product> ProductService::getAll() {
    std::vector<Product> products;
    const std::string query = "SELECT p.*, ad.name as direction_name FROM products p LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id ORDER BY p.code LIMIT 100";
    try {
        auto result = m_db.execute(query);
        for (const auto& row : result) products.push_back(Product::fromRow(row));
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return products;
}

std::optional<Product> ProductService::getByCode(const std::string& code) {
    const std::string query = "SELECT p.*, ad.name as direction_name FROM products p LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id WHERE p.code = $1";
    try {
        auto result = m_db.executeParams(query, {code});
        if (!result.empty()) return Product::fromRow(result[0]);
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return std::nullopt;
}

std::vector<Product> ProductService::getByDirection(int directionId) {
    std::vector<Product> products;
    const std::string query = "SELECT p.*, ad.name as direction_name FROM products p LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id WHERE p.anchor_direction_id = $1 ORDER BY p.code";
    try {
        auto result = m_db.executeParams(query, {std::to_string(directionId)});
        for (const auto& row : result) products.push_back(Product::fromRow(row));
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return products;
}

std::vector<Product> ProductService::getNewArrivals() {
    std::vector<Product> products;
    const std::string query = "SELECT p.*, ad.name as direction_name FROM products p LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id WHERE p.is_new_arrival = TRUE AND p.in_stock_balance > 0 ORDER BY p.created_at DESC";
    try {
        auto result = m_db.execute(query);
        for (const auto& row : result) products.push_back(Product::fromRow(row));
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return products;
}

std::vector<Product> ProductService::getInStock() {
    std::vector<Product> products;
    const std::string query = "SELECT p.*, ad.name as direction_name FROM products p LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id WHERE p.in_stock_balance > 0 ORDER BY p.code";
    try {
        auto result = m_db.execute(query);
        for (const auto& row : result) products.push_back(Product::fromRow(row));
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return products;
}

std::vector<Product> ProductService::search(const std::string& searchQuery) {
    std::vector<Product> products;
    const std::string query = "SELECT p.*, ad.name as direction_name FROM products p LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id WHERE LOWER(p.name) LIKE LOWER($1) OR p.code LIKE $2 ORDER BY p.code LIMIT 50";
    try {
        std::string likePattern = "%" + searchQuery + "%";
        auto result = m_db.executeParams(query, {likePattern, likePattern});
        for (const auto& row : result) products.push_back(Product::fromRow(row));
    } catch (const std::exception& e) { LOG_ERROR(e.what()); }
    return products;
}

} // namespace utsk
