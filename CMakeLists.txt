cmake_minimum_required(VERSION 3.0.0)

set(CLIENT_PROJECT_NAME otel-matlab)
set(CLIENT_EXECUTABLE_NAME otel-matlab)

project(${CLIENT_PROJECT_NAME} VERSION 0.1.0)

set(LIBMEXCLASS_EXTERNAL_PROJECT_TARGET_NAME libmexclass)

# ####################
# Client Configuration
# ####################

# Specify locations to opentelemetry-cpp
set(OPENTELEMETRY_CPP_INSTALL ${CMAKE_CURRENT_SOURCE_DIR}/../Downloads/opentelemetry-cpp/install)

# Specify locations to dependent libraries of opentelemetry-cpp
set(CURL_INSTALL ${CMAKE_CURRENT_SOURCE_DIR}/../Downloads/opentelemetry-cpp/opentelemetry-cpp/tools/vcpkg/packages/curl_x64-windows)
set(PROTOBUF_INSTALL ${CMAKE_CURRENT_SOURCE_DIR}/../Downloads/opentelemetry-cpp/opentelemetry-cpp/tools/vcpkg/packages/protobuf_x64-windows)

# Specify location for find_package to locate opentelemetry-cpp-config.cmake
set(opentelemetry-cpp_DIR ${OPENTELEMETRY_CPP_INSTALL}/lib/cmake/opentelemetry-cpp)
find_package(opentelemetry-cpp CONFIG REQUIRED)

set(TRACE_API_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/trace/include)
set(TRACE_SDK_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/trace/include)
set(CUSTOM_PROXY_FACTORY_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR} ${TRACE_API_INCLUDE_DIR} ${TRACE_SDK_INCLUDE_DIR} ${OPENTELEMETRY_CPP_INCLUDE_DIRS})

set(CUSTOM_PROXY_FACTORY_HEADER_FILENAME OtelMatlabProxyFactory.h)
set(CUSTOM_PROXY_FACTORY_CLASS_NAME OtelMatlabProxyFactory)

set(CUSTOM_PROXY_FACTORY_SOURCES_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(CUSTOM_PROXY_FACTORY_SOURCES
    ${CUSTOM_PROXY_FACTORY_SOURCES_DIR}/${CUSTOM_PROXY_FACTORY_CLASS_NAME}.cpp
)

set(TRACE_API_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/trace/include)
set(TRACE_SDK_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/trace/include)
set(CUSTOM_PROXY_INCLUDE_DIR ${TRACE_API_INCLUDE_DIR} ${TRACE_SDK_INCLUDE_DIR})

set(TRACE_API_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/trace/src)
set(TRACE_SDK_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/trace/src)
set(CUSTOM_PROXY_SOURCES
    ${TRACE_API_SOURCE_DIR}/TracerProviderProxy.cpp
    ${TRACE_API_SOURCE_DIR}/TracerProxy.cpp
    ${TRACE_API_SOURCE_DIR}/SpanProxy.cpp
    ${TRACE_API_SOURCE_DIR}/SpanContextProxy.cpp
    ${TRACE_API_SOURCE_DIR}/attribute.cpp
    ${TRACE_SDK_SOURCE_DIR}/TracerProviderProxy.cpp
    ${TRACE_SDK_SOURCE_DIR}/BatchSpanProcessorProxy.cpp
    ${TRACE_SDK_SOURCE_DIR}/ParentBasedSamplerProxy.cpp
)

set(DEBUG_OR_RELEASE $<$<CONFIG:Debug>:DEBUG>$<$<CONFIG:Release>:RELEASE>)

# FIXME: Why does this not work?
#set(CUSTOM_PROXY_LINK_LIBRARIES ${OPENTELEMETRY_CPP_LIBRARIES})

set(CUSTOM_PROXY_LINK_LIBRARIES "${OPENTELEMETRY_CPP_LIBRARY_DIRS}/opentelemetry_trace.lib"
    "${OPENTELEMETRY_CPP_LIBRARY_DIRS}/opentelemetry_common.lib"
    "${OPENTELEMETRY_CPP_LIBRARY_DIRS}/opentelemetry_logs.lib"
    "${OPENTELEMETRY_CPP_LIBRARY_DIRS}/opentelemetry_resources.lib"
    "${OPENTELEMETRY_CPP_LIBRARY_DIRS}/opentelemetry_version.lib"
    "${OPENTELEMETRY_CPP_LIBRARY_DIRS}/opentelemetry_http_client_curl.lib"
    "${OPENTELEMETRY_CPP_LIBRARY_DIRS}/opentelemetry_proto.lib"
    "${OPENTELEMETRY_CPP_LIBRARY_DIRS}/opentelemetry_exporter_ostream_span.lib"
    "${OPENTELEMETRY_CPP_LIBRARY_DIRS}/opentelemetry_exporter_otlp_http.lib"
    "${OPENTELEMETRY_CPP_LIBRARY_DIRS}/opentelemetry_exporter_otlp_http_client.lib"
    "${OPENTELEMETRY_CPP_LIBRARY_DIRS}/opentelemetry_otlp_recordable.lib"
    "${CURL_INSTALL}/lib/libcurl.lib"
    "${PROTOBUF_INSTALL}/lib/libprotobuf.lib"
    "${PROTOBUF_INSTALL}/lib/libprotobuf-lite.lib"
    "${PROTOBUF_INSTALL}/lib/libprotoc.lib")


set(RUNTIME_BINDIR $<$<CONFIG:Debug>:debug/bin>$<$<CONFIG:Release>:bin>)
set(RUNTIME_SUFFIX $<$<CONFIG:Debug>:d>$<$<CONFIG:Release>:>)
set(CUSTOM_PROXY_RUNTIME_LIBRARIES "${CURL_INSTALL}/${RUNTIME_BINDIR}/libcurl${RUNTIME_SUFFIX}.dll"
    "${PROTOBUF_INSTALL}/${RUNTIME_BINDIR}/libprotobuf${RUNTIME_SUFFIX}.dll"
    "${PROTOBUF_INSTALL}/${RUNTIME_BINDIR}/libprotobuf-lite${RUNTIME_SUFFIX}.dll"
    "${PROTOBUF_INSTALL}/${RUNTIME_BINDIR}/libprotoc${RUNTIME_SUFFIX}.dll")

# Add libmexclass as an external project.
include(ExternalProject)
# GIT_TAG for libmexclass source from Git.
# Note: Clients who don't want to depend on main (which may have breaking changes) can specify a specific 
# commit using the LIBMEXCLASS_GIT_TAG argument with cmake command. By default source from the main branch will be used.
set(LIBMEXCLASS_GIT_TAG main CACHE STRING "")
message(STATUS "LIBMEXCLASS_GIT_TAG: ${LIBMEXCLASS_GIT_TAG}")
ExternalProject_Add(
    # Name of the external project target.
    ${LIBMEXCLASS_EXTERNAL_PROJECT_TARGET_NAME}
    GIT_REPOSITORY https://github.com/mathworks/libmexclass.git
    GIT_TAG ${LIBMEXCLASS_GIT_TAG}
    # Source directory for libmexclass.
    SOURCE_SUBDIR libmexclass/cpp
    CMAKE_CACHE_ARGS "-D CUSTOM_PROXY_FACTORY_INCLUDE_DIR:STRING=${CUSTOM_PROXY_FACTORY_INCLUDE_DIR}"
                     "-D CUSTOM_PROXY_FACTORY_SOURCES:STRING=${CUSTOM_PROXY_FACTORY_SOURCES}"
		     "-D CUSTOM_PROXY_INCLUDE_DIR:STRING=${CUSTOM_PROXY_INCLUDE_DIR}"
                     "-D CUSTOM_PROXY_SOURCES:STRING=${CUSTOM_PROXY_SOURCES}"
		     "-D CUSTOM_PROXY_LINK_LIBRARIES:STRING=${CUSTOM_PROXY_LINK_LIBRARIES}"
		     "-D CUSTOM_PROXY_RUNTIME_LIBRARIES:STRING=${CUSTOM_PROXY_RUNTIME_LIBRARIES}"
                     "-D CUSTOM_PROXY_FACTORY_HEADER_FILENAME:STRING=${CUSTOM_PROXY_FACTORY_HEADER_FILENAME}"
                     "-D CUSTOM_PROXY_FACTORY_CLASS_NAME:STRING=${CUSTOM_PROXY_FACTORY_CLASS_NAME}"
    # Install the external project
    INSTALL_COMMAND ${CMAKE_COMMAND} --build . --config ${DEBUG_OR_RELEASE} --target install
)

# Get the installation directory for libmexclass.
ExternalProject_Get_Property(${LIBMEXCLASS_EXTERNAL_PROJECT_TARGET_NAME} BINARY_DIR)

set(TRACE_API_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/api/trace/+opentelemetry)
set(TRACE_SDK_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/sdk/trace/+opentelemetry)

# Copy only the packaged folder +libmexclass from the installation directory
install(DIRECTORY ${BINARY_DIR}/+libmexclass DESTINATION libmexclass)
install(DIRECTORY ${TRACE_API_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${TRACE_SDK_MATLAB_SOURCES} DESTINATION .)
