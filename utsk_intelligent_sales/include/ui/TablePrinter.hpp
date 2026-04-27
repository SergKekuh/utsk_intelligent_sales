#ifndef TABLE_PRINTER_HPP
#define TABLE_PRINTER_HPP

#include <vector>
#include <string>
#include <iostream>
#include <iomanip>
#include <algorithm>

namespace utsk {

/**
 * @brief Класс для красивого вывода таблиц в консоль
 */
class TablePrinter {
public:
    enum class Alignment { Left, Right, Center };

    struct Column {
        std::string header;
        int width;
        Alignment align;
    };

    TablePrinter() = default;

    TablePrinter& setTitle(const std::string& title);
    TablePrinter& addColumn(const std::string& header, int width, 
                            Alignment align = Alignment::Left);
    TablePrinter& addRow(const std::vector<std::string>& row);
    TablePrinter& addSeparator();
    void print();
    void clear();

private:
    void printLine(char left, char mid, char right, char fill);
    void printRow(const std::vector<std::string>& row);
    std::string alignText(const std::string& text, int width, Alignment align);

    std::string m_title;
    std::vector<Column> m_columns;
    std::vector<std::vector<std::string>> m_rows;
};

} // namespace utsk

#endif // TABLE_PRINTER_HPP
