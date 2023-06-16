cmake_minimum_required(VERSION 3.0.0)

cmake_policy(SET CMP0074 NEW)

set(CLIENT_PROJECT_NAME otel-matlab)

project(${CLIENT_PROJECT_NAME} VERSION 0.1.0)

# ######################################
# Options
# ######################################

option(WITH_OTLP_GRPC "Whether to include the OTLP gRPC exporter" OFF)

# ######################################
# libmexclass FetchContent Configuration
# ######################################

set(LIBMEXCLASS_FETCH_CONTENT_NAME libmexclass)

set(LIBMEXCLASS_FETCH_CONTENT_GIT_REPOSITORY "https://github.com/mathworks/libmexclass.git")

set(LIBMEXCLASS_FETCH_CONTENT_GIT_TAG main CACHE STRING "") 

set(LIBMEXCLASS_FETCH_CONTENT_SOURCE_SUBDIR "libmexclass/cpp")

include(FetchContent)
FetchContent_Declare(
    ${LIBMEXCLASS_FETCH_CONTENT_NAME}
    GIT_REPOSITORY ${LIBMEXCLASS_FETCH_CONTENT_GIT_REPOSITORY}
    GIT_TAG ${LIBMEXCLASS_FETCH_CONTENT_GIT_TAG}
    SOURCE_SUBDIR ${LIBMEXCLASS_FETCH_CONTENT_SOURCE_SUBDIR}
)
FetchContent_MakeAvailable(
    ${LIBMEXCLASS_FETCH_CONTENT_NAME}
)

# ###########################
# OpenTelemetry Proxy Library
# ###########################


set(OPENTELEMETRY_PROXY_LIBRARY_NAME "OtelMatlabProxy")

# Specify location for find_package to locate opentelemetry-cpp-config.cmake
find_package(opentelemetry-cpp CONFIG REQUIRED)
find_package(CURL REQUIRED)
find_package(Protobuf REQUIRED)
find_package(nlohmann_json REQUIRED)
if(WIN32)
    find_package(zlib REQUIRED)
endif()
if(WITH_OTLP_GRPC)
    find_package(gRPC REQUIRED)
    find_package(absl REQUIRED)
    find_package(c-ares REQUIRED)
    find_package(re2 REQUIRED)
    if(WIN32)
        find_package(openssl REQUIRED)
    elseif(UNIX AND NOT APPLE AND NOT CYGWIN)
        find_package(upb REQUIRED)
    endif()
endif()

set(TRACE_API_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/trace/include) 
set(CONTEXT_API_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/context/include) 
set(BAGGAGE_API_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/baggage/include) 
set(TRACE_SDK_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/trace/include)
set(OTLP_EXPORTER_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/include)
set(OPENTELEMETRY_PROXY_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR} ${TRACE_API_INCLUDE_DIR} ${CONTEXT_API_INCLUDE_DIR} ${BAGGAGE_API_INCLUDE_DIR} ${TRACE_SDK_INCLUDE_DIR} ${OTLP_EXPORTER_INCLUDE_DIR} ${OPENTELEMETRY_CPP_INCLUDE_DIRS})

set(OPENTELEMETRY_PROXY_FACTORY_CLASS_NAME OtelMatlabProxyFactory)
set(OPENTELEMETRY_PROXY_FACTORY_SOURCES_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(TRACE_API_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/trace/src)
set(CONTEXT_API_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/context/src)
set(BAGGAGE_API_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/baggage/src)
set(TRACE_SDK_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/trace/src)
set(OTLP_EXPORTER_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/src)
set(OPENTELEMETRY_PROXY_SOURCES
    ${OPENTELEMETRY_PROXY_FACTORY_SOURCES_DIR}/${OPENTELEMETRY_PROXY_FACTORY_CLASS_NAME}.cpp
    ${TRACE_API_SOURCE_DIR}/TracerProviderProxy.cpp
    ${TRACE_API_SOURCE_DIR}/TracerProxy.cpp
    ${TRACE_API_SOURCE_DIR}/SpanProxy.cpp
    ${TRACE_API_SOURCE_DIR}/SpanContextProxy.cpp
    ${TRACE_API_SOURCE_DIR}/attribute.cpp
    ${CONTEXT_API_SOURCE_DIR}/TextMapPropagatorProxy.cpp
    ${CONTEXT_API_SOURCE_DIR}/CompositePropagatorProxy.cpp
    ${CONTEXT_API_SOURCE_DIR}/TextMapCarrierProxy.cpp
    ${CONTEXT_API_SOURCE_DIR}/ContextProxy.cpp
    ${BAGGAGE_API_SOURCE_DIR}/BaggageProxy.cpp
    ${TRACE_SDK_SOURCE_DIR}/TracerProviderProxy.cpp
    ${TRACE_SDK_SOURCE_DIR}/SimpleSpanProcessorProxy.cpp
    ${TRACE_SDK_SOURCE_DIR}/BatchSpanProcessorProxy.cpp
    ${TRACE_SDK_SOURCE_DIR}/ParentBasedSamplerProxy.cpp
    ${OTLP_EXPORTER_SOURCE_DIR}/OtlpHttpSpanExporterProxy.cpp
)
if(WITH_OTLP_GRPC)
    set(OPENTELEMETRY_PROXY_SOURCES ${OPENTELEMETRY_PROXY_SOURCES} 
        ${OTLP_EXPORTER_SOURCE_DIR}/OtlpGrpcSpanExporterProxy.cpp)
endif()

libmexclass_client_add_proxy_library(
    NAME ${OPENTELEMETRY_PROXY_LIBRARY_NAME}
    SOURCES ${OPENTELEMETRY_PROXY_SOURCES}
    INCLUDE_DIRS ${OPENTELEMETRY_PROXY_INCLUDE_DIRS}
)

# Additional compiler flags for gRPC exporter
if(WITH_OTLP_GRPC)
    if(WIN32)
        set(OTLP_GRPC_MACRO /DWITH_OTLP_GRPC)
    else()
        set(OTLP_GRPC_MACRO "-D WITH_OTLP_GRPC")
    endif()

    target_compile_options(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE ${OTLP_GRPC_MACRO})
endif()

# link against OpenTelemetry-cpp libraries and their dependencies
target_link_libraries(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE ${OPENTELEMETRY_CPP_LIBRARIES})

# On Linux, when linking with certain static libraries, need to force include entire archive to avoid the linker mistakenly leaving out symbols
if(UNIX AND NOT APPLE AND NOT CYGWIN)
    set(OPENTELEMETRY_PROXY_LINK_OPTIONS -Wl,--whole-archive 
        "${OPENTELEMETRY_CPP_LIBRARY_DIRS}/libopentelemetry_trace.a"
        "${OPENTELEMETRY_CPP_LIBRARY_DIRS}/libopentelemetry_common.a"
        ${ABSL_LIBRARIES}
        ${UPB_LIBRARIES} -Wl,--no-whole-archive)
    target_link_options(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE ${OPENTELEMETRY_PROXY_LINK_OPTIONS})
endif()

# Use C++17 
target_compile_features(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE cxx_std_17)

if(WIN32)
    # runtime dependent libraries
    set(DEPENDS_BINDIR $<$<CONFIG:Debug>:debug/bin>$<$<CONFIG:Release>:bin>)
    FILE(GLOB CURL_RUNTIME ${CURL_INCLUDE_DIRS}/../bin/*.dll)
    FILE(GLOB ZLIB_RUNTIME ${ZLIB_INCLUDE_DIRS}/../bin/*.dll)

    set(OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES ${CURL_RUNTIME}
	${PROTOBUF_RUNTIME}
        ${ZLIB_RUNTIME})
    if(WITH_OTLP_GRPC)
        FILE(GLOB ABSEIL_RUNTIME ${ABSL_INCLUDE_DIRS}/../bin/*.dll)
        FILE(GLOB C_ARES_RUNTIME ${C-ARES_INCLUDE_DIR}/../bin/*.dll)
        FILE(GLOB OPENSSL_RUNTIME ${OPENSSL_INCLUDE_DIR}/../bin/*.dll)
        FILE(GLOB RE2_RUNTIME ${RE2_INCLUDE_DIR}/../bin/*.dll)
        FILE(GLOB PROTOBUF_RUNTIME ${PROTOBUF_INCLUDE_DIRS}/../bin/*.dll)
	set(OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES ${OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES}
            ${ABSEIL_RUNTIME}
            ${C_ARES_RUNTIME}
            ${OPENSSL_RUNTIME}
            ${RE2_RUNTIME})
    endif()
elseif(UNIX AND NOT APPLE AND NOT CYGWIN)
    FILE(GLOB OTEL_CPP_RUNTIME ${OPENTELEMETRY_CPP_LIBRARY_DIRS}/*.so)
    set(OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES ${OTEL_CPP_RUNTIME})
endif()

# ##############################
# OpenTelemetry MEX Gateway
# ##############################

# Create the MEX gateway target.

set(OPENTELEMETRY_MEX_GATEWAY_NAME "gateway")
set(OPENTELEMETRY_MEX_GATEWAY_SOURCES ${CMAKE_SOURCE_DIR}/mex/gateway.cpp)

libmexclass_client_add_mex_gateway(
    NAME ${OPENTELEMETRY_MEX_GATEWAY_NAME}
    CLIENT_PROXY_LIBRARY_NAME ${OPENTELEMETRY_PROXY_LIBRARY_NAME}
    SOURCES ${OPENTELEMETRY_MEX_GATEWAY_SOURCES}
)

# ###############################
# libmexclass Client Installation
# ###############################

libmexclass_client_install(
    CLIENT_PROXY_LIBRARY_NAME ${OPENTELEMETRY_PROXY_LIBRARY_NAME}
    CLIENT_MEX_GATEWAY_NAME ${OPENTELEMETRY_MEX_GATEWAY_NAME}
    DESTINATION "."
)

# Install M files
set(TRACE_API_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/api/trace/+opentelemetry)
set(CONTEXT_API_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/api/context/+opentelemetry)
set(BAGGAGE_API_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/api/baggage/+opentelemetry)
set(TRACE_SDK_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/sdk/trace/+opentelemetry)
set(OTLP_HTTP_EXPORTER_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpHttpSpanExporter.m)
set(OTLP_GRPC_EXPORTER_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpGrpcSpanExporter.m)

set(OTLP_EXPORTERS_DIR +opentelemetry/+exporters/+otlp)

install(DIRECTORY ${TRACE_API_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${CONTEXT_API_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${BAGGAGE_API_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${TRACE_SDK_MATLAB_SOURCES} DESTINATION .)
install(FILES ${OTLP_HTTP_EXPORTER_MATLAB_SOURCES} DESTINATION ${OTLP_EXPORTERS_DIR})
if(WITH_OTLP_GRPC)
    install(FILES ${OTLP_GRPC_EXPORTER_MATLAB_SOURCES} DESTINATION ${OTLP_EXPORTERS_DIR})
endif()

# Install dependent runtime libraries
install(FILES ${OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES} DESTINATION +libmexclass/+proxy)
