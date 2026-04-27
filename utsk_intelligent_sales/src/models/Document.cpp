#include "models/Document.hpp"

namespace utsk {

Document Document::fromRow(const pqxx::row& row) {
    Document doc;
    
    doc.setId(row["id"].as<long long>());
    doc.setClientCode(row["client_code"].as<std::string>());
    doc.setInvoiceDate(row["invoice_date"].as<std::string>());
    
    try { if (!row["total_amount"].is_null()) doc.setTotalAmount(row["total_amount"].as<double>()); } catch(...) {}
    
    return doc;
}

} // namespace utsk
