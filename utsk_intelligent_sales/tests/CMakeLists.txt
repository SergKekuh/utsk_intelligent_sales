cmake_minimum_required(VERSION 3.16)

set(GTEST_ROOT "/usr/src/gtest")
set(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${GTEST_ROOT})

find_package(GTest QUIET)

if(NOT GTest_FOUND)
    set(GTEST_INCLUDE_DIR /usr/include)
    set(GTEST_LIBRARY /usr/lib/x86_64-linux-gnu/libgtest.a)
    set(GTEST_MAIN_LIBRARY /usr/lib/x86_64-linux-gnu/libgtest_main.a)
    
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
    message(STATUS "GTest: using ${GTEST_LIBRARY}")
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

target_include_directories(utsk_tests PRIVATE ../include ${PQXX_INCLUDE_DIRS})
target_link_libraries(utsk_tests ${PQXX_LIBRARIES} nlohmann_json::nlohmann_json GTest::GTest GTest::Main pthread)
target_compile_options(utsk_tests PRIVATE -Wno-deprecated-declarations)
