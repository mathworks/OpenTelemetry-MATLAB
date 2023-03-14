cmake_minimum_required(VERSION 3.0.0)

set(CLIENT_PROJECT_NAME otel-matlab)
set(CLIENT_EXECUTABLE_NAME otel-matlab)

project(${CLIENT_PROJECT_NAME} VERSION 0.1.0)

set(LIBMEXCLASS_EXTERNAL_PROJECT_TARGET_NAME libmexclass)
# TODO: Change to Git repository URL in production.
set(LIBMEXCLASS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../Downloads/libmexclass/libmexclass/libmexclass/cpp)

# ####################
# Client Configuration
# ####################

# TODO: Use find_package(opentelemetry-cpp) instead of hardcoding location
set(OPENTELEMETRY_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/../Downloads/opentelemetry-cpp/opentelemetry-cpp)
set(TRACE_API_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/trace/include)
set(TRACE_SDK_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/trace/include)
set(CUSTOM_PROXY_FACTORY_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR} ${TRACE_API_INCLUDE_DIR} ${TRACE_SDK_INCLUDE_DIR} "${OPENTELEMETRY_ROOT}/sdk/include" "${OPENTELEMETRY_ROOT}/api/include" "${OPENTELEMETRY_ROOT}/exporters/otlp/include" "${OPENTELEMETRY_ROOT}/exporters/ostream/include") 

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
)

set(DEBUG_OR_RELEASE $<$<CONFIG:Debug>:DEBUG>$<$<CONFIG:Release>:RELEASE>)
set(CUSTOM_PROXY_LINK_LIBRARIES "${OPENTELEMETRY_ROOT}/build/sdk/src/trace/${DEBUG_OR_RELEASE}/opentelemetry_trace.lib"
    "${OPENTELEMETRY_ROOT}/build/sdk/src/common/${DEBUG_OR_RELEASE}/opentelemetry_common.lib"
    "${OPENTELEMETRY_ROOT}/build/sdk/src/logs/${DEBUG_OR_RELEASE}/opentelemetry_logs.lib"
    "${OPENTELEMETRY_ROOT}/build/sdk/src/resource/${DEBUG_OR_RELEASE}/opentelemetry_resources.lib"
    "${OPENTELEMETRY_ROOT}/build/sdk/src/version/${DEBUG_OR_RELEASE}/opentelemetry_version.lib"
    "${OPENTELEMETRY_ROOT}/build/ext/src/http/client/curl/${DEBUG_OR_RELEASE}/opentelemetry_http_client_curl.lib"
    "${OPENTELEMETRY_ROOT}/build/${DEBUG_OR_RELEASE}/opentelemetry_proto.lib"
    "${OPENTELEMETRY_ROOT}/build/exporters/ostream/${DEBUG_OR_RELEASE}/opentelemetry_exporter_ostream_span.lib"
    "${OPENTELEMETRY_ROOT}/build/exporters/otlp/${DEBUG_OR_RELEASE}/opentelemetry_exporter_otlp_http.lib"
    "${OPENTELEMETRY_ROOT}/build/exporters/otlp/${DEBUG_OR_RELEASE}/opentelemetry_exporter_otlp_http_client.lib"
    "${OPENTELEMETRY_ROOT}/build/exporters/otlp/${DEBUG_OR_RELEASE}/opentelemetry_otlp_recordable.lib"
    "${OPENTELEMETRY_ROOT}/tools/vcpkg/packages/curl_x64-windows/lib/libcurl.lib"
    "${OPENTELEMETRY_ROOT}/tools/vcpkg/packages/protobuf_x64-windows/lib/libprotobuf.lib"
    "${OPENTELEMETRY_ROOT}/tools/vcpkg/packages/protobuf_x64-windows/lib/libprotobuf-lite.lib"
    "${OPENTELEMETRY_ROOT}/tools/vcpkg/packages/protobuf_x64-windows/lib/libprotoc.lib")

set(RUNTIME_BINDIR $<$<CONFIG:Debug>:debug/bin>$<$<CONFIG:Release>:bin>)
set(RUNTIME_SUFFIX $<$<CONFIG:Debug>:d>$<$<CONFIG:Release>:>)
set(CUSTOM_PROXY_RUNTIME_LIBRARIES "${OPENTELEMETRY_ROOT}/tools/vcpkg/packages/curl_x64-windows/${RUNTIME_BINDIR}/libcurl${RUNTIME_SUFFIX}.dll"
    "${OPENTELEMETRY_ROOT}/tools/vcpkg/packages/protobuf_x64-windows/${RUNTIME_BINDIR}/libprotobuf${RUNTIME_SUFFIX}.dll"
    "${OPENTELEMETRY_ROOT}/tools/vcpkg/packages/protobuf_x64-windows/${RUNTIME_BINDIR}/libprotobuf-lite${RUNTIME_SUFFIX}.dll"
    "${OPENTELEMETRY_ROOT}/tools/vcpkg/packages/protobuf_x64-windows/${RUNTIME_BINDIR}/libprotoc${RUNTIME_SUFFIX}.dll")

# Add libmexclass as an external project.
include(ExternalProject)
ExternalProject_Add(
    # Name of the external project target.
    ${LIBMEXCLASS_EXTERNAL_PROJECT_TARGET_NAME}
    # Don't download anything. Instead, use the local libmexclass sources.
    # TODO: This should be removed when using the Git repository URL.
    DOWNLOAD_COMMAND ""
    # Source directory for libmexclass.
    # TODO: This should be removed when using the Git repository URL.
    SOURCE_DIR ${LIBMEXCLASS_DIR}
    # Client's must supply the following information:
    #
    # 1. CUSTOM_PROXY_FACTORY_INCLUDE_DIR
    # 2. CUSTOM_PROXY_FACTORY_SOURCES
    # 3. CUSTOM_PROXY_INCLUDE_DIR
    # 4. CUSTOM_PROXY_SOURCES
    #
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
