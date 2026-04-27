cmake_minimum_required(VERSION 3.16)

# ====== GTest: поиск без NO_DEFAULT_PATH ======
find_path(GTEST_INCLUDE_DIR gtest/gtest.h
    PATHS /usr/src/gtest/include /usr/include /usr/local/include
)
find_library(GTEST_LIBRARY gtest
    PATHS /usr/src/gtest/lib /usr/lib /usr/lib/x86_64-linux-gnu /usr/local/lib
)
find_library(GTEST_MAIN_LIBRARY gtest_main
    PATHS /usr/src/gtest/lib /usr/lib /usr/lib/x86_64-linux-gnu /usr/local/lib
)

# Если не нашли — пробуем find_package
if(NOT GTEST_LIBRARY)
    find_package(GTest QUIET)
    if(GTest_FOUND)
        set(GTEST_LIBRARY GTest::GTest)
        set(GTEST_MAIN_LIBRARY GTest::Main)
        get_target_property(GTEST_INCLUDE_DIR GTest::GTest INTERFACE_INCLUDE_DIRECTORIES)
    endif()
endif()

if(NOT GTEST_LIBRARY)
    message(FATAL_ERROR "GTest not found. Install: sudo apt install libgtest-dev && cd /usr/src/gtest && sudo cmake . && sudo make && sudo cp lib/*.a /usr/lib/x86_64-linux-gnu/")
endif()

message(STATUS "GTest: ${GTEST_LIBRARY}")

# ====== Остальное ======
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
