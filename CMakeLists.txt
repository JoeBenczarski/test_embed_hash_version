cmake_minimum_required(VERSION 3.0.0)
project(main VERSION 0.1.0)

include(cmake/CheckVersion.cmake)
CheckVersion()

add_executable(${CMAKE_PROJECT_NAME} main.cpp)
target_link_libraries(${CMAKE_PROJECT_NAME} version)
