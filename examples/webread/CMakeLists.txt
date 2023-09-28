
add_executable(http_server cpp/server.cc)

target_include_directories(http_server PRIVATE ${OTEL_CPP_PREFIX}/include)
target_link_libraries(http_server PRIVATE ${OTEL_CPP_LINK_LIBRARIES})
