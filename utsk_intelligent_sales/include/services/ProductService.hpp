#ifndef PRODUCT_SERVICE_HPP
#define PRODUCT_SERVICE_HPP

#include <vector>
#include <optional>
#include "models/Product.hpp"
#include "core/Database.hpp"

namespace utsk {

class ProductService {
public:
    explicit ProductService(Database& db);
    ~ProductService() = default;

    std::vector<Product> getAll();
    std::optional<Product> getByCode(const std::string& code);
    std::vector<Product> getByDirection(int directionId);
    std::vector<Product> getNewArrivals();
    std::vector<Product> getInStock();
    std::vector<Product> search(const std::string& query);

private:
    Database& m_db;
};

} // namespace utsk

#endif // PRODUCT_SERVICE_HPP
