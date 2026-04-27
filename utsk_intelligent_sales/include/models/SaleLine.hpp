#ifndef SALE_LINE_HPP
#define SALE_LINE_HPP

#include <string>
#include <pqxx/pqxx>

namespace utsk {

class SaleLine {
public:
    SaleLine() = default;

    long long getDocumentId() const { return m_documentId; }
    void setDocumentId(long long id) { m_documentId = id; }

    const std::string& getProductCode() const { return m_productCode; }
    void setProductCode(const std::string& code) { m_productCode = code; }

    double getQuantity() const { return m_quantity; }
    void setQuantity(double qty) { m_quantity = qty; }

    double getAmount() const { return m_amount; }
    void setAmount(double amount) { m_amount = amount; }

    static SaleLine fromRow(const pqxx::row& row);

private:
    long long m_documentId = 0;
    std::string m_productCode;
    double m_quantity = 0.0;
    double m_amount = 0.0;
};

} // namespace utsk

#endif // SALE_LINE_HPP
