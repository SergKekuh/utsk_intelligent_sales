#ifndef CONSOLE_MENU_HPP
#define CONSOLE_MENU_HPP

#include <vector>
#include <string>
#include <functional>

namespace utsk {

/**
 * @brief Простое консольное меню
 */
class ConsoleMenu {
public:
    struct MenuItem {
        std::string key;
        std::string description;
        std::function<void()> action;
    };

    ConsoleMenu() = default;

    void setTitle(const std::string& title) { m_title = title; }
    void addItem(const std::string& key, const std::string& description, 
                 std::function<void()> action);
    void addSeparator(const std::string& text = "");
    void run();
    void exit();

private:
    void display();
    void clearScreen();

    std::string m_title = "MENU";
    std::vector<MenuItem> m_items;
    bool m_running = false;
};

} // namespace utsk

#endif // CONSOLE_MENU_HPP
