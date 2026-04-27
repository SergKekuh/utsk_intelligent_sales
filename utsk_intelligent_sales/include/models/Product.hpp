#ifndef PRODUCT_HPP
#define PRODUCT_HPP

#include <string>
#include <optional>
#include <pqxx/pqxx>

namespace utsk {

class Product {
public:
    Product() = default;

    const std::string& getCode() const { return m_code; }
    void setCode(const std::string& code) { m_code = code; }

    const std::string& getName() const { return m_name; }
    void setName(const std::string& name) { m_name = name; }

    std::optional<int> getDirectionId() const { return m_directionId; }
    void setDirectionId(int id) { m_directionId = id; }

    std::optional<std::string> getDirectionName() const { return m_directionName; }
    void setDirectionName(const std::string& name) { m_directionName = name; }

    std::optional<std::string> getMaterialGrade() const { return m_materialGrade; }
    void setMaterialGrade(const std::string& grade) { m_materialGrade = grade; }

    bool isNewArrival() const { return m_isNewArrival; }
    void setIsNewArrival(bool isNew) { m_isNewArrival = isNew; }

    double getInStockBalance() const { return m_inStockBalance; }
    void setInStockBalance(double balance) { m_inStockBalance = balance; }

    static Product fromRow(const pqxx::row& row);

private:
    std::string m_code;
    std::string m_name;
    std::optional<int> m_directionId;
    std::optional<std::string> m_directionName;
    std::optional<std::string> m_materialGrade;
    bool m_isNewArrival = false;
    double m_inStockBalance = 0.0;
};

} // namespace utsk

#endif // PRODUCT_HPP
