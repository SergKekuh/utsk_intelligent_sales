cmake_minimum_required(VERSION 3.16)

# ====== GTest: ручной поиск ======
set(GTEST_ROOT "/usr/src/gtest" CACHE PATH "GTest source directory")

find_path(GTEST_INCLUDE_DIR gtest/gtest.h
    PATHS ${GTEST_ROOT}/include
          /usr/include
          /usr/local/include
    NO_DEFAULT_PATH
)
find_library(GTEST_LIBRARY gtest
    PATHS ${GTEST_ROOT}/lib
          /usr/lib
          /usr/lib/x86_64-linux-gnu
          /usr/local/lib
    NO_DEFAULT_PATH
)
find_library(GTEST_MAIN_LIBRARY gtest_main
    PATHS ${GTEST_ROOT}/lib
          /usr/lib
          /usr/lib/x86_64-linux-gnu
          /usr/local/lib
    NO_DEFAULT_PATH
)

if(NOT GTEST_LIBRARY)
    message(FATAL_ERROR "GTest not found. Build it first: cd /usr/src/gtest && sudo cmake . && sudo make && sudo cp lib/*.a /usr/lib/x86_64-linux-gnu/")
endif()

message(STATUS "GTest found: ${GTEST_LIBRARY}")

# ====== Остальные зависимости ======
find_package(nlohmann_json REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(PQXX REQUIRED libpqxx)

# ====== Тестовый executable ======
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
