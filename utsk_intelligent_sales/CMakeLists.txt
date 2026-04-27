cmake_minimum_required(VERSION 3.16)
project(UTSK_Intelligent_Sales VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

option(BUILD_TESTS "Build unit tests" OFF)
option(BUILD_GUI "Build Qt GUI version" OFF)

find_package(PkgConfig REQUIRED)

# Поиск libpqxx
pkg_check_modules(PQXX REQUIRED libpqxx)

# Поиск nlohmann_json через pkg-config
pkg_check_modules(JSON REQUIRED nlohmann_json)

add_executable(utsk_console
    src/main_console.cpp
    src/core/Database.cpp
    src/core/Config.cpp
    src/core/Logger.cpp
    src/models/Client.cpp
    src/models/Product.cpp
    src/models/Document.cpp
    src/models/SaleLine.cpp
    src/services/ClientService.cpp
    src/services/ProductService.cpp
    src/services/AnalyticsService.cpp
    src/services/RecommendationService.cpp
    src/ui/ConsoleUI.cpp
    src/ui/ConsoleMenu.cpp
    src/ui/TablePrinter.cpp
)

target_include_directories(utsk_console PRIVATE include ${PQXX_INCLUDE_DIRS} ${JSON_INCLUDE_DIRS})
target_link_libraries(utsk_console ${PQXX_LIBRARIES} ${JSON_LIBRARIES})
target_compile_options(utsk_console PRIVATE ${PQXX_CFLAGS_OTHER})
add_subdirectory(tests)
