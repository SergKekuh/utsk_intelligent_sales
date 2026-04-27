# cmake/CompilerOptions.cmake
# Строгие настройки компилятора для проекта UTSK

function(utsk_set_compiler_options target_name)
    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
        target_compile_options(${target_name} PRIVATE
            -Wall
            -Wextra
            -Wpedantic
            -Wconversion
            -Wsign-conversion
            -Wshadow
            -Werror=return-type
        )
        if(CMAKE_BUILD_TYPE STREQUAL "Debug")
            target_compile_options(${target_name} PRIVATE -g -O0)
        elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
            target_compile_options(${target_name} PRIVATE -O3 -DNDEBUG)
        endif()
    elseif(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
        target_compile_options(${target_name} PRIVATE
            /W4
            /WX-
            /permissive-
            /Zc:__cplusplus
        )
    endif()
endfunction()
