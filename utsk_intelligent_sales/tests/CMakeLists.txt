cmake_minimum_required(VERSION 3.16)

# Указываем путь к GTest явно
set(GTEST_ROOT "/usr/src/gtest" CACHE PATH "GTest root")
set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${GTEST_ROOT})

# Пробуем найти GTest
find_package(GTest QUIET)

# Если не нашли — используем собранные библиотеки напрямую
if(NOT GTest_FOUND)
    message(STATUS "GTest not found by find_package, using direct paths")
    
    set(GTEST_INCLUDE_DIR /usr/src/gtest/include)
    set(GTEST_LIBRARY /usr/src/gtest/lib/libgtest.a)
    set(GTEST_MAIN_LIBRARY /usr/src/gtest/lib/libgtest_main.a)
    
    if(NOT EXISTS "${GTEST_LIBRARY}")
        message(FATAL_ERROR "GTest library not found at ${GTEST_LIBRARY}. Build it first.")
    endif()
    
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
)

target_link_libraries(utsk_tests
    ${PQXX_LIBRARIES}
    nlohmann_json::nlohmann_json
    GTest::GTest
    GTest::Main
    pthread
)

target_compile_options(utsk_tests PRIVATE -Wno-deprecated-declarations)
