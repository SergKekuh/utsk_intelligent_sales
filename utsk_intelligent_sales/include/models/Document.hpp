#ifndef DOCUMENT_HPP
#define DOCUMENT_HPP

#include <string>
#include <pqxx/pqxx>

namespace utsk {

class Document {
public:
    Document() = default;

    long long getId() const { return m_id; }
    void setId(long long id) { m_id = id; }

    const std::string& getClientCode() const { return m_clientCode; }
    void setClientCode(const std::string& code) { m_clientCode = code; }

    const std::string& getInvoiceDate() const { return m_invoiceDate; }
    void setInvoiceDate(const std::string& date) { m_invoiceDate = date; }

    double getTotalAmount() const { return m_totalAmount; }
    void setTotalAmount(double amount) { m_totalAmount = amount; }

    static Document fromRow(const pqxx::row& row);

private:
    long long m_id = 0;
    std::string m_clientCode;
    std::string m_invoiceDate;
    double m_totalAmount = 0.0;
};

} // namespace utsk

#endif // DOCUMENT_HPP
