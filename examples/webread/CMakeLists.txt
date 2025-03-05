
set(WEBREAD_EXAMPLE_TARGET webread_example_server)
add_executable(${WEBREAD_EXAMPLE_TARGET} cpp/server.cc)
if(NOT DEFINED OTEL_CPP_INSTALLED_DIR)
    add_dependencies(${WEBREAD_EXAMPLE_TARGET} ${OTEL_CPP_PROJECT_NAME})
endif()

# Specify the ABI version, include directories, and libraries of otel-cpp. The C++ code in this example directly calls otel-cpp functions.
target_compile_definitions(${WEBREAD_EXAMPLE_TARGET} PRIVATE ${OTEL_CPP_ABI_VERSION})
target_include_directories(${WEBREAD_EXAMPLE_TARGET} PRIVATE ${OTEL_CPP_PREFIX}/include)
target_link_libraries(${WEBREAD_EXAMPLE_TARGET} PRIVATE ${OPENTELEMETRY_PROXY_LINK_LIBRARIES})
if(UNIX AND NOT APPLE AND NOT CYGWIN)
    target_link_options(${WEBREAD_EXAMPLE_TARGET} PRIVATE ${OPENTELEMETRY_PROXY_LINK_OPTIONS})
elseif(APPLE)
    set_target_properties(${WEBREAD_EXAMPLE_TARGET} PROPERTIES BUILD_RPATH "${CMAKE_INSTALL_PREFIX}/${LIBMEXCLASS_PROXY_INSTALLED_DIR}")
endif()
# use the same C++ standard as OpenTelemetry-cpp if known, otherwise just use the default C++14
if(NOT DEFINED OTEL_CPP_INSTALLED_DIR)
    target_compile_features(${WEBREAD_EXAMPLE_TARGET} PRIVATE cxx_std_${OTEL_CPP_CXX_STANDARD})
else()
    target_compile_features(${WEBREAD_EXAMPLE_TARGET} PRIVATE cxx_std_14)
endif()
