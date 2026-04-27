cmake_minimum_required(VERSION 3.16)

# Простой ручной поиск GTest
find_path(GTEST_INCLUDE_DIR gtest/gtest.h
    PATHS /usr/include /usr/local/include /usr/src/gtest/include
)
find_library(GTEST_LIBRARY gtest
    PATHS /usr/lib /usr/local/lib /usr/lib/x86_64-linux-gnu
)
find_library(GTEST_MAIN_LIBRARY gtest_main
    PATHS /usr/lib /usr/local/lib /usr/lib/x86_64-linux-gnu
)

# Если не нашли — используем find_package
if(NOT GTEST_LIBRARY)
    find_package(GTest REQUIRED)
    set(GTEST_LIBRARY GTest::GTest)
    set(GTEST_MAIN_LIBRARY GTest::Main)
endif()

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
    ${GTEST_INCLUDE_DIR}
)

target_link_libraries(utsk_tests
    ${PQXX_LIBRARIES}
    nlohmann_json::nlohmann_json
    ${GTEST_LIBRARY}
    ${GTEST_MAIN_LIBRARY}
    pthread
)

target_compile_options(utsk_tests PRIVATE -Wno-deprecated-declarations)
