#include "ui/ConsoleMenu.hpp"
#include <iostream>
#include <limits>

namespace utsk {

void ConsoleMenu::addItem(const std::string& key, const std::string& description, 
                          std::function<void()> action) {
    m_items.push_back({key, description, action});
}

void ConsoleMenu::addSeparator(const std::string& text) {
    if (text.empty()) {
        m_items.push_back({"---", "", nullptr});
    } else {
        m_items.push_back({"---", text, nullptr});
    }
}

void ConsoleMenu::clearScreen() {
    std::cout << "\033[2J\033[1;1H";
}

void ConsoleMenu::display() {
    clearScreen();
    
    std::cout << "\n+------------------------------------------------------+\n";
    std::cout << "|          " << m_title << "\n";
    std::cout << "+------------------------------------------------------+\n";
    
    for (const auto& item : m_items) {
        if (item.key == "---") {
            if (item.description.empty()) {
                std::cout << "|                                                      |\n";
            } else {
                std::cout << "|  " << item.description << "\n";
            }
        } else {
            std::cout << "|  [" << item.key << "] " << item.description;
            int len = 5 + item.key.length() + item.description.length();
            int padding = 52 - len;
            if (padding > 0) {
                std::cout << std::string(padding, ' ');
            }
            std::cout << "|\n";
        }
    }
    
    std::cout << "+------------------------------------------------------+\n";
    std::cout << "\nВыберите действие: ";
}

void ConsoleMenu::run() {
    m_running = true;
    
    while (m_running) {
        display();
        
        std::string input;
        std::cin >> input;
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
        
        bool found = false;
        for (const auto& item : m_items) {
            if (item.key == input && item.action) {
                item.action();
                found = true;
                break;
            }
        }
        
        if (!found && input != "0" && input != "q") {
            std::cout << "\nНеверный выбор. Нажмите Enter для продолжения...";
            std::cin.get();
        }
    }
}

void ConsoleMenu::exit() {
    m_running = false;
}

} // namespace utsk
