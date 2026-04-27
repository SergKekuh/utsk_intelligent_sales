cmake_minimum_required(VERSION 3.16)

# Ручной поиск GTest
find_path(GTEST_INCLUDE_DIR gtest/gtest.h
    PATHS /usr/include /usr/local/include /usr/src/gtest/include
)
find_library(GTEST_LIBRARY gtest
    PATHS /usr/lib /usr/local/lib /usr/lib/x86_64-linux-gnu /usr/src/gtest/lib
)
find_library(GTEST_MAIN_LIBRARY gtest_main
    PATHS /usr/lib /usr/local/lib /usr/lib/x86_64-linux-gnu /usr/src/gtest/lib
)

if(NOT GTEST_LIBRARY)
    message(STATUS "GTest libraries not found, building from source...")
    
    # Скачиваем и собираем GTest
    include(ExternalProject)
    ExternalProject_Add(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG v1.14.0
        CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=/tmp/gtest
        UPDATE_COMMAND ""
        INSTALL_COMMAND ""
    )
    
    set(GTEST_INCLUDE_DIR /tmp/gtest/include)
    set(GTEST_LIBRARY /tmp/gtest/lib/libgtest.a)
    set(GTEST_MAIN_LIBRARY /tmp/gtest/lib/libgtest_main.a)
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
