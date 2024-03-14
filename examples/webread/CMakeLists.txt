
set(WEBREAD_EXAMPLE_TARGET webread_example_server)
add_executable(${WEBREAD_EXAMPLE_TARGET} cpp/server.cc)
add_dependencies(${WEBREAD_EXAMPLE_TARGET} ${OTEL_CPP_PROJECT_NAME})

target_include_directories(${WEBREAD_EXAMPLE_TARGET} PRIVATE ${OTEL_CPP_PREFIX}/include)
target_link_libraries(${WEBREAD_EXAMPLE_TARGET} PRIVATE ${OPENTELEMETRY_PROXY_LINK_LIBRARIES})
if(UNIX AND NOT APPLE AND NOT CYGWIN)
    target_link_options(${WEBREAD_EXAMPLE_TARGET} PRIVATE ${OPENTELEMETRY_PROXY_LINK_OPTIONS})
elseif(APPLE)
    set_target_properties(${WEBREAD_EXAMPLE_TARGET} PROPERTIES BUILD_RPATH "${CMAKE_INSTALL_PREFIX}/${LIBMEXCLASS_PROXY_INSTALLED_DIR}")
endif()
# use the same C++ standard as OpenTelemetry-cpp
target_compile_features(${WEBREAD_EXAMPLE_TARGET} PRIVATE cxx_std_${OTEL_CPP_CXX_STANDARD})
