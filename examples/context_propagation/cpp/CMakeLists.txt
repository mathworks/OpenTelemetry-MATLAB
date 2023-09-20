cmake_minimum_required(VERSION 3.7.0)

# allow overriding package roots
cmake_policy(SET CMP0074 NEW)

project(example_client VERSION 1.0.0)

find_package(CURL REQUIRED)
find_package(Protobuf REQUIRED)
find_package(nlohmann_json REQUIRED)
find_package(opentelemetry-cpp CONFIG REQUIRED)

add_executable(http_client client.cc)

target_include_directories(http_client PRIVATE ${OPENTELEMETRY_CPP_INCLUDE_DIRS})
target_link_libraries(http_client PRIVATE ${OPENTELEMETRY_CPP_LIBRARIES})
