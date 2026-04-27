#include "models/SaleLine.hpp"

namespace utsk {

SaleLine SaleLine::fromRow(const pqxx::row& row) {
    SaleLine line;
    
    line.setDocumentId(row["document_id"].as<long long>());
    line.setProductCode(row["product_code"].as<std::string>());
    line.setQuantity(row["quantity"].as<double>());
    line.setAmount(row["amount"].as<double>());
    
    return line;
}

} // namespace utsk
