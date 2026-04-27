cmake_minimum_required(VERSION 3.16)

# Ищем GTest — сначала стандартный способ, затем ручной
find_package(GTest QUIET)

if(NOT GTest_FOUND)
    message(STATUS "GTest not found, trying manual setup...")
    
    # Ручной поиск
    find_path(GTEST_INCLUDE_DIR gtest/gtest.h
        PATHS /usr/include /usr/local/include
    )
    find_library(GTEST_LIBRARY gtest
        PATHS /usr/lib /usr/local/lib /usr/lib/x86_64-linux-gnu
    )
    find_library(GTEST_MAIN_LIBRARY gtest_main
        PATHS /usr/lib /usr/local/lib /usr/lib/x86_64-linux-gnu
    )
    
    if(GTEST_INCLUDE_DIR AND GTEST_LIBRARY)
        message(STATUS "GTest found manually:")
        message(STATUS "  Include: ${GTEST_INCLUDE_DIR}")
        message(STATUS "  Library: ${GTEST_LIBRARY}")
        
        add_library(GTest::GTest UNKNOWN IMPORTED)
        set_target_properties(GTest::GTest PROPERTIES
            IMPORTED_LOCATION ${GTEST_LIBRARY}
            INTERFACE_INCLUDE_DIRECTORIES ${GTEST_INCLUDE_DIR}
        )
    else()
        message(FATAL_ERROR "GTest not found! Install: sudo apt install libgtest-dev")
    endif()
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

# Не используем gtest_discover_tests — просто собираем
