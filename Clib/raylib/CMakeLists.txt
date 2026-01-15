cmake_minimum_required(VERSION 3.10)
project(simple_raylib_wrapper C)

# Find the raylib library
set(RAYLIB_DIR ${CMAKE_CURRENT_SOURCE_DIR})

# Enable OpenMP for parallel rendering
find_package(OpenMP)

# Create the wrapper library
add_library(simple_raylib_wrapper STATIC simple_raylib_impl.c)
target_include_directories(simple_raylib_wrapper PRIVATE ${RAYLIB_DIR})
target_link_libraries(simple_raylib_wrapper PRIVATE ${RAYLIB_DIR}/raylib.lib)

# Enable OpenMP if available
if(OpenMP_C_FOUND)
    target_link_libraries(simple_raylib_wrapper PRIVATE OpenMP::OpenMP_C)
    message(STATUS "OpenMP enabled for parallel SDF rendering")
endif()

# Optimization flags for Release build
if(MSVC)
    target_compile_options(simple_raylib_wrapper PRIVATE /O2 /fp:fast /arch:AVX2)
endif()

# Output name
set_target_properties(simple_raylib_wrapper PROPERTIES OUTPUT_NAME "simple_raylib_wrapper")
