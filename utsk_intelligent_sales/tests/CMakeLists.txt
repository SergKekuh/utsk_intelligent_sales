cmake_minimum_required(VERSION 3.16)

# Супер-простой поиск GTest
find_package(GTest REQUIRED)

find_package(nlohmann_json REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(PQXX REQUIRED libpqxx)

add_executable(utsk_tests
    unit/test_database.cpp
    ../src/core/Database.cpp
    ../src/core/Config.cpp
    ../src/core/Logger.cpp
)

target_include_directories(utsk_tests PRIVATE 
    ../include 
    ${PQXX_INCLUDE_DIRS}
)

target_link_libraries(utsk_tests
    ${PQXX_LIBRARIES}
    nlohmann_json::nlohmann_json
    GTest::GTest
    GTest::Main
    pthread
)

target_compile_options(utsk_tests PRIVATE -Wno-deprecated-declarations)
