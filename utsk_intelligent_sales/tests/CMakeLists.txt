cmake_minimum_required(VERSION 3.16)

# ЖЁСТКИЕ ПУТИ к GTest (работает и локально, и в CI)
set(GTEST_INCLUDE_DIR "/usr/include")
set(GTEST_LIBRARY "/usr/lib/x86_64-linux-gnu/libgtest.a")
set(GTEST_MAIN_LIBRARY "/usr/lib/x86_64-linux-gnu/libgtest_main.a")

# Если библиотек нет — ошибка с подсказкой
if(NOT EXISTS "${GTEST_LIBRARY}")
    message(FATAL_ERROR "GTest not found at ${GTEST_LIBRARY}. Build: cd /usr/src/gtest && sudo cmake . && sudo make && sudo cp lib/libgtest*.a /usr/lib/x86_64-linux-gnu/")
endif()

message(STATUS "GTest: ${GTEST_LIBRARY}")

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
