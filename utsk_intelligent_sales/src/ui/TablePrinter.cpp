#include "ui/TablePrinter.hpp"

namespace utsk {

TablePrinter& TablePrinter::setTitle(const std::string& title) {
    m_title = title;
    return *this;
}

TablePrinter& TablePrinter::addColumn(const std::string& header, int width, Alignment align) {
    m_columns.push_back({header, width, align});
    return *this;
}

TablePrinter& TablePrinter::addRow(const std::vector<std::string>& row) {
    m_rows.push_back(row);
    return *this;
}

TablePrinter& TablePrinter::addSeparator() {
    m_rows.push_back({"---"});
    return *this;
}

void TablePrinter::clear() {
    m_title.clear();
    m_columns.clear();
    m_rows.clear();
}

std::string TablePrinter::alignText(const std::string& text, int width, Alignment align) {
    if (static_cast<int>(text.length()) >= width) {
        return text.substr(0, width - 2) + "..";
    }
    
    int padding = width - text.length();
    
    switch (align) {
        case Alignment::Left:
            return text + std::string(padding, ' ');
        case Alignment::Right:
            return std::string(padding, ' ') + text;
        case Alignment::Center:
            int leftPad = padding / 2;
            int rightPad = padding - leftPad;
            return std::string(leftPad, ' ') + text + std::string(rightPad, ' ');
    }
    return text;
}

void TablePrinter::printLine(char left, char mid, char right, char fill) {
    std::cout << left;
    for (size_t i = 0; i < m_columns.size(); ++i) {
        std::cout << std::string(m_columns[i].width, fill);
        if (i < m_columns.size() - 1) {
            std::cout << mid;
        }
    }
    std::cout << right << "\n";
}

void TablePrinter::printRow(const std::vector<std::string>& row) {
    if (row.size() == 1 && row[0] == "---") {
        printLine('+', '+', '+', '-');
        return;
    }
    
    std::cout << "|";
    for (size_t i = 0; i < m_columns.size() && i < row.size(); ++i) {
        std::cout << alignText(row[i], m_columns[i].width, m_columns[i].align);
        if (i < m_columns.size() - 1) {
            std::cout << "|";
        }
    }
    std::cout << "|\n";
}

void TablePrinter::print() {
    if (m_columns.empty()) return;
    
    // Заголовок
    if (!m_title.empty()) {
        int totalWidth = 1; // начальная граница
        for (const auto& col : m_columns) {
            totalWidth += col.width + 1; // ширина + разделитель
        }
        
        std::cout << "\n+" << std::string(totalWidth, '-') << "+\n";
        std::cout << "|" << alignText(m_title, totalWidth, Alignment::Center) << "|\n";
        printLine('+', '+', '+', '-');
    } else {
        printLine('+', '+', '+', '-');
    }
    
    // Заголовки колонок
    std::vector<std::string> headers;
    for (const auto& col : m_columns) {
        headers.push_back(col.header);
    }
    printRow(headers);
    printLine('+', '+', '+', '-');
    
    // Данные
    for (const auto& row : m_rows) {
        printRow(row);
    }
    
    // Нижняя граница
    printLine('+', '+', '+', '-');
    std::cout << "\n";
}

} // namespace utsk
