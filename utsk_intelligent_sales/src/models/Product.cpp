#include "models/Product.hpp"

namespace utsk {

Product Product::fromRow(const pqxx::row& row) {
    Product product;
    
    product.setCode(row["code"].as<std::string>());
    product.setName(row["name"].as<std::string>());
    
    try { if (!row["anchor_direction_id"].is_null()) product.setDirectionId(row["anchor_direction_id"].as<int>()); } catch(...) {}
    try { if (!row["direction_name"].is_null()) product.setDirectionName(row["direction_name"].as<std::string>()); } catch(...) {}
    try { if (!row["material_grade"].is_null()) product.setMaterialGrade(row["material_grade"].as<std::string>()); } catch(...) {}
    try { if (!row["is_new_arrival"].is_null()) product.setIsNewArrival(row["is_new_arrival"].as<bool>()); } catch(...) {}
    try { if (!row["in_stock_balance"].is_null()) product.setInStockBalance(row["in_stock_balance"].as<double>()); } catch(...) {}
    
    return product;
}

} // namespace utsk
