cmake_minimum_required(VERSION 3.16)

# Ищем заголовки GTest
find_path(GTEST_INCLUDE_DIR gtest/gtest.h
    PATHS /usr/include /usr/local/include /usr/src/gtest/include
)

# Ищем библиотеки
find_library(GTEST_LIBRARY gtest
    PATHS /usr/lib /usr/local/lib /usr/lib/x86_64-linux-gnu
)
find_library(GTEST_MAIN_LIBRARY gtest_main
    PATHS /usr/lib /usr/local/lib /usr/lib/x86_64-linux-gnu
)

if(NOT GTEST_INCLUDE_DIR OR NOT GTEST_LIBRARY)
    message(FATAL_ERROR "GTest not found. Include: ${GTEST_INCLUDE_DIR}, Lib: ${GTEST_LIBRARY}")
endif()

message(STATUS "GTest include: ${GTEST_INCLUDE_DIR}")
message(STATUS "GTest library: ${GTEST_LIBRARY}")

# Создаём imported target
add_library(GTest::GTest UNKNOWN IMPORTED)
set_target_properties(GTest::GTest PROPERTIES
    IMPORTED_LOCATION ${GTEST_LIBRARY}
    INTERFACE_INCLUDE_DIRECTORIES ${GTEST_INCLUDE_DIR}
)
add_library(GTest::Main UNKNOWN IMPORTED)
set_target_properties(GTest::Main PROPERTIES
    IMPORTED_LOCATION ${GTEST_MAIN_LIBRARY}
    INTERFACE_INCLUDE_DIRECTORIES ${GTEST_INCLUDE_DIR}
)

find_package(nlohmann_json REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(PQXX REQUIRED libpqxx)

add_executable(utsk_tests
    unit/test_database.cpp
    ../src/core/Database.cpp
    ../src/core/Config.cpp
    ../src/core/Logger.cpp
)

target_include_directories(utsk_tests PRIVATE ../include ${PQXX_INCLUDE_DIRS})
target_link_libraries(utsk_tests ${PQXX_LIBRARIES} nlohmann_json::nlohmann_json GTest::GTest GTest::Main pthread)
target_compile_options(utsk_tests PRIVATE -Wno-deprecated-declarations)
