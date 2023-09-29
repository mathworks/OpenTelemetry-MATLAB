cmake_minimum_required(VERSION 3.7.0)

cmake_policy(SET CMP0074 NEW)


# ###########################
# vcpkg
# ###########################

include(FetchContent)

# check if VCPKG_ROOT is defined, which should point to an existing installation
if(DEFINED ENV{VCPKG_ROOT})
   # Autodetect vcpkg toolchain
   if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
       string(REPLACE "\\" "/" CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
   endif()
else()
   # VCPKG_ROOT not defined, get it using FetchContent

   if(DEFINED VCPKG_PREFIX})
       # download location specified
       string(REPLACE "\\" "/" VCPKG_PREFIX "${VCPKG_PREFIX}")
   else()
       set(VCPKG_PREFIX ${CMAKE_BINARY_DIR}/vcpkg)
   endif()

   # On Mac, there is a conflict between libcurl and the version in MATLAB, so 
   # use libcurl as a shared library and load the MATLAB version at runtime
   if(APPLE)
       # run uname -m to determine whether arm64 or x86_64
       exec_program(uname ARGS -m OUTPUT_VARIABLE MAC_HOST_SYSTEM)
       set(VCPKG_OTEL_TRIPLET ${MAC_HOST_SYSTEM}-osx-otel-matlab)
       set(VCPKG_OVERLAY_TRIPLETS ${CMAKE_SOURCE_DIR}/cmake/vcpkg_triplets)
       set(VCPKG_TARGET_TRIPLET ${VCPKG_OTEL_TRIPLET})
   endif()

   set(VCPKG_FETCH_CONTENT_NAME vcpkg)
   set(VCPKG_GIT_REPOSITORY "https://github.com/microsoft/vcpkg.git")
   set(VCPKG_GIT_TAG "9edb1b8")
   FetchContent_Declare(
       ${VCPKG_FETCH_CONTENT_NAME}
       GIT_REPOSITORY ${VCPKG_GIT_REPOSITORY}
       GIT_TAG ${VCPKG_GIT_TAG}
       PREFIX ${VCPKG_PREFIX}
       UPDATE_DISCONNECTED 1
   )

   FetchContent_MakeAvailable(
       ${VCPKG_FETCH_CONTENT_NAME}
   )

   FetchContent_GetProperties(${VCPKG_FETCH_CONTENT_NAME})
   string(REPLACE "\\" "/" CMAKE_TOOLCHAIN_FILE "${vcpkg_SOURCE_DIR}/scripts/buildsystems/vcpkg.cmake")

endif()

if(NOT DEFINED VCPKG_INSTALLED_DIR)
   set(VCPKG_INSTALLED_DIR ${CMAKE_BINARY_DIR}/vcpkg_installed)
endif()

# ######################################
# Options
# ######################################

option(WITH_OTLP_HTTP "Whether to include the OTLP HTTP exporter" ON)
option(WITH_OTLP_GRPC "Whether to include the OTLP gRPC exporter" OFF)
if(NOT WITH_OTLP_HTTP AND NOT WITH_OTLP_GRPC)
    message(FATAL_ERROR "At least one of WITH_OTLP_HTTP and WITH_OTLP_GRPC must be ON")
endif()
if(APPLE)
    option(SKIP_OTEL_CPP_PATCH "Whether to skip patching OpenTelemetry-cpp" OFF)
endif()
option(WITH_EXAMPLES "Whether to build examples" OFF)

# set vcpkg features depending on specified options
set(VCPKG_MANIFEST_FEATURES "")  # start with empty
if(WITH_OTLP_HTTP)
    set(VCPKG_MANIFEST_FEATURES ${VCPKG_MANFIEST_FEATURES} "otlp-http")
endif()
if(WITH_OTLP_GRPC)
    set(VCPKG_MANIFEST_FEATURES ${VCPKG_MANIFEST_FEATURES} "otlp-grpc")
endif()

# ######################################
# Project Declaration
# ######################################

set(CLIENT_PROJECT_NAME otel-matlab)

project(${CLIENT_PROJECT_NAME} VERSION 0.1.0)

# ######################################
# libmexclass 
# ######################################

set(LIBMEXCLASS_FETCH_CONTENT_NAME libmexclass)

set(LIBMEXCLASS_FETCH_CONTENT_GIT_REPOSITORY "https://github.com/mathworks/libmexclass.git")

set(LIBMEXCLASS_FETCH_CONTENT_GIT_TAG "77f3d72") 

set(LIBMEXCLASS_FETCH_CONTENT_SOURCE_SUBDIR "libmexclass/cpp")

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
# OpenTelemetry-cpp 
# ###########################

if(DEFINED OTEL_CPP_INSTALLED_DIR)
   # OTEL_CPP_INSTALLED_DIR should point to an installed location of OpenTelemetry-cpp 
   string(REPLACE "\\" "/" OTEL_CPP_PREFIX ${OTEL_CPP_INSTALLED_DIR})
else()
   # No installed location supplied. Fetch it as an external project
   include(ExternalProject)
   set(OTEL_CPP_PROJECT_NAME opentelemetry-cpp)
   set(OTEL_CPP_GIT_REPOSITORY "https://github.com/open-telemetry/opentelemetry-cpp.git")
   set(OTEL_CPP_GIT_TAG "11d5d9e")

   if(DEFINED OTEL_CPP_PREFIX)
       string(REPLACE "\\" "/" OTEL_CPP_PREFIX ${OTEL_CPP_PREFIX})
   else()
       set(OTEL_CPP_PREFIX ${CMAKE_BINARY_DIR}/otel-cpp)
   endif()

   if(WITH_OTLP_GRPC)
       set(OTEL_CPP_CXX_STANDARD 14)  # Abseil requires at least Cxx14
   else()
       set(OTEL_CPP_CXX_STANDARD 11)
   endif()

   if(NOT APPLE OR SKIP_OTEL_CPP_PATCH)
       set(patch_command "")
   else()
       set(patch_command git apply ${CMAKE_SOURCE_DIR}/otel-cpp.patch)
   endif()

   ExternalProject_Add(
       ${OTEL_CPP_PROJECT_NAME}
       GIT_REPOSITORY ${OTEL_CPP_GIT_REPOSITORY}
       GIT_TAG ${OTEL_CPP_GIT_TAG}
       PREFIX ${OTEL_CPP_PREFIX}
       UPDATE_DISCONNECTED 1
       PATCH_COMMAND ${patch_command}
       CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DWITH_OTLP_HTTP=${WITH_OTLP_HTTP} -DWITH_OTLP_GRPC=${WITH_OTLP_GRPC} -DBUILD_TESTING=OFF -DWITH_BENCHMARK=OFF -DOPENTELEMETRY_INSTALL=ON -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} -DCMAKE_CXX_STANDARD=${OTEL_CPP_CXX_STANDARD} -DVCPKG_INSTALLED_DIR=${VCPKG_INSTALLED_DIR}
       INSTALL_DIR ${OTEL_CPP_PREFIX}
       INSTALL_COMMAND ${CMAKE_COMMAND} --install . --prefix ${OTEL_CPP_PREFIX}
   )
endif()

# ###########################
# OpenTelemetry Proxy Library
# ###########################


set(OPENTELEMETRY_PROXY_LIBRARY_NAME "OtelMatlabProxy")

find_package(Protobuf REQUIRED)
find_package(nlohmann_json REQUIRED)
if(WIN32)
    find_package(zlib REQUIRED)
endif()

if(WITH_OTLP_HTTP)
    find_package(CURL REQUIRED)
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
set(COMMON_API_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/common/include) 
set(TRACE_SDK_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/trace/include)
set(COMMON_SDK_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/common/include)
set(OTLP_EXPORTER_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/include)
set(OPENTELEMETRY_PROXY_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR} ${TRACE_API_INCLUDE_DIR} ${CONTEXT_API_INCLUDE_DIR} ${BAGGAGE_API_INCLUDE_DIR} ${COMMON_API_INCLUDE_DIR} ${TRACE_SDK_INCLUDE_DIR} ${COMMON_SDK_INCLUDE_DIR} ${OTLP_EXPORTER_INCLUDE_DIR} ${OTEL_CPP_PREFIX}/include)

set(OPENTELEMETRY_PROXY_FACTORY_CLASS_NAME OtelMatlabProxyFactory)
set(OPENTELEMETRY_PROXY_FACTORY_SOURCES_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(TRACE_API_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/trace/src)
set(CONTEXT_API_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/context/src)
set(BAGGAGE_API_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/baggage/src)
set(COMMON_API_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/common/src)
set(TRACE_SDK_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/trace/src)
set(COMMON_SDK_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/common/src)
set(OTLP_EXPORTER_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/src)
set(OPENTELEMETRY_PROXY_SOURCES
    ${OPENTELEMETRY_PROXY_FACTORY_SOURCES_DIR}/${OPENTELEMETRY_PROXY_FACTORY_CLASS_NAME}.cpp
    ${TRACE_API_SOURCE_DIR}/TracerProviderProxy.cpp
    ${TRACE_API_SOURCE_DIR}/TracerProxy.cpp
    ${TRACE_API_SOURCE_DIR}/SpanProxy.cpp
    ${TRACE_API_SOURCE_DIR}/SpanContextProxy.cpp
    ${COMMON_API_SOURCE_DIR}/attribute.cpp
    ${CONTEXT_API_SOURCE_DIR}/TextMapPropagatorProxy.cpp
    ${CONTEXT_API_SOURCE_DIR}/CompositePropagatorProxy.cpp
    ${CONTEXT_API_SOURCE_DIR}/TextMapCarrierProxy.cpp
    ${CONTEXT_API_SOURCE_DIR}/ContextProxy.cpp
    ${BAGGAGE_API_SOURCE_DIR}/BaggageProxy.cpp
    ${TRACE_SDK_SOURCE_DIR}/TracerProviderProxy.cpp
    ${TRACE_SDK_SOURCE_DIR}/SimpleSpanProcessorProxy.cpp
    ${TRACE_SDK_SOURCE_DIR}/BatchSpanProcessorProxy.cpp
    ${TRACE_SDK_SOURCE_DIR}/ParentBasedSamplerProxy.cpp
    ${COMMON_SDK_SOURCE_DIR}/resource.cpp)
if(WITH_OTLP_HTTP)
    set(OPENTELEMETRY_PROXY_SOURCES ${OPENTELEMETRY_PROXY_SOURCES} 
	${OTLP_EXPORTER_SOURCE_DIR}/OtlpHttpSpanExporterProxy.cpp)
endif()
if(WITH_OTLP_GRPC)
    set(OPENTELEMETRY_PROXY_SOURCES ${OPENTELEMETRY_PROXY_SOURCES} 
        ${OTLP_EXPORTER_SOURCE_DIR}/OtlpGrpcSpanExporterProxy.cpp)
endif()

libmexclass_client_add_proxy_library(
    NAME ${OPENTELEMETRY_PROXY_LIBRARY_NAME}
    SOURCES ${OPENTELEMETRY_PROXY_SOURCES}
    INCLUDE_DIRS ${OPENTELEMETRY_PROXY_INCLUDE_DIRS}
)

# Additional compiler flags for HTTP/gRPC exporters
if(WITH_OTLP_HTTP)
    if(WIN32)
	set(OTLP_MACROS /DWITH_OTLP_HTTP)
    else()
	set(OTLP_MACROS "-D WITH_OTLP_HTTP ")
    endif()
endif()

if(WITH_OTLP_GRPC)
    if(WIN32)
	set(OTLP_MACROS ${OTLP_MACROS} /DWITH_OTLP_GRPC)
    else()
	set(OTLP_MACROS ${OTLP_MACROS} "-D WITH_OTLP_GRPC ")
    endif()
endif()
    
# On Windows, suppress a compiler warning about deprecation of result_of
if(WIN32)
    set(CUSTOM_CXX_FLAGS -D_SILENCE_CXX17_RESULT_OF_DEPRECATION_WARNING)
else()
    set(CUSTOM_CXX_FLAGS "")
endif()

if(WIN32)
    set(OTEL_PROTO_LIBRARY_SUFFIX ${CMAKE_STATIC_LIBRARY_SUFFIX})
else()
    set(OTEL_PROTO_LIBRARY_SUFFIX ${CMAKE_SHARED_LIBRARY_SUFFIX})
endif()

target_compile_options(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE ${OTLP_MACROS} ${CUSTOM_CXX_FLAGS})

# link against OpenTelemetry-cpp libraries and their dependencies
set(OTEL_CPP_LINK_LIBRARIES ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_common${CMAKE_STATIC_LIBRARY_SUFFIX}
	${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_otlp_recordable${CMAKE_STATIC_LIBRARY_SUFFIX}
        ${OTEL_CPP_PREFIX}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}opentelemetry_proto${OTEL_PROTO_LIBRARY_SUFFIX}
	${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_resources${CMAKE_STATIC_LIBRARY_SUFFIX}
	${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_trace${CMAKE_STATIC_LIBRARY_SUFFIX}
	${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_version${CMAKE_STATIC_LIBRARY_SUFFIX}
	${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_logs${CMAKE_STATIC_LIBRARY_SUFFIX}
	${Protobuf_LIBRARIES})
if(WITH_OTLP_HTTP)
    set(OTEL_CPP_LINK_LIBRARIES ${OTEL_CPP_LINK_LIBRARIES} ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_http${CMAKE_STATIC_LIBRARY_SUFFIX}
	    ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_http_client${CMAKE_STATIC_LIBRARY_SUFFIX}
	    ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_http_client_curl${CMAKE_STATIC_LIBRARY_SUFFIX}
	    ${CURL_LIBRARIES})
endif()
if(WITH_OTLP_GRPC)
    set(OTEL_CPP_LINK_LIBRARIES ${OTEL_CPP_LINK_LIBRARIES} ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_grpc${CMAKE_STATIC_LIBRARY_SUFFIX}
	    ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_grpc_client${CMAKE_STATIC_LIBRARY_SUFFIX}
            ${OTEL_CPP_PREFIX}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}opentelemetry_proto_grpc${OTEL_PROTO_LIBRARY_SUFFIX}
	    gRPC::grpc++
	    absl::synchronization)
endif()

target_link_libraries(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE ${OTEL_CPP_LINK_LIBRARIES})

# On Linux, when linking with certain static libraries, need to force include entire archive to avoid the linker mistakenly leaving out symbols
if(UNIX AND NOT APPLE AND NOT CYGWIN)
    set(OPENTELEMETRY_PROXY_LINK_OPTIONS -Wl,--whole-archive 
	"${OTEL_CPP_PREFIX}/lib/libopentelemetry_trace.a"
	"${OTEL_CPP_PREFIX}/lib/libopentelemetry_common.a"
	"${OTEL_CPP_PREFIX}/lib/libopentelemetry_otlp_recordable.a"
        ${ABSL_LIBRARIES}
        ${UPB_LIBRARIES} -Wl,--no-whole-archive)
    target_link_options(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE ${OPENTELEMETRY_PROXY_LINK_OPTIONS})
elseif(APPLE)
    set_target_properties(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PROPERTIES INSTALL_RPATH "@executable_path")
endif()

# Use C++17 
target_compile_features(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE cxx_std_17)

if(WIN32)
    # runtime dependent libraries
    set(DEPENDS_BINDIR $<$<CONFIG:Debug>:debug/bin>$<$<CONFIG:Release>:bin>)
    FILE(GLOB PROTOBUF_RUNTIME ${PROTOBUF_INCLUDE_DIRS}/../bin/*.dll)
    FILE(GLOB ZLIB_RUNTIME ${ZLIB_INCLUDE_DIRS}/../bin/*.dll)

    set(OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES ${PROTOBUF_RUNTIME}
        ${ZLIB_RUNTIME})

    if(WITH_OTLP_HTTP)
        FILE(GLOB CURL_RUNTIME ${CURL_INCLUDE_DIRS}/../bin/*.dll)
	set(OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES ${OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES}
	    ${CURL_RUNTIME})
    endif()

    if(WITH_OTLP_GRPC)
        FILE(GLOB ABSEIL_RUNTIME ${ABSL_INCLUDE_DIRS}/../bin/*.dll)
        FILE(GLOB C_ARES_RUNTIME ${C-ARES_INCLUDE_DIR}/../bin/*.dll)
        FILE(GLOB OPENSSL_RUNTIME ${OPENSSL_INCLUDE_DIR}/../bin/*.dll)
        FILE(GLOB RE2_RUNTIME ${RE2_INCLUDE_DIR}/../bin/*.dll)
	set(OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES ${OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES}
            ${ABSEIL_RUNTIME}
            ${C_ARES_RUNTIME}
            ${OPENSSL_RUNTIME}
            ${RE2_RUNTIME})
    endif()
elseif(UNIX AND NOT CYGWIN)
    if(WITH_OTLP_GRPC)
        set(OTEL_CPP_RUNTIME ${OTEL_CPP_PREFIX}/lib/libopentelemetry_proto${CMAKE_SHARED_LIBRARY_SUFFIX}
                             ${OTEL_CPP_PREFIX}/lib/libopentelemetry_proto_grpc${CMAKE_SHARED_LIBRARY_SUFFIX})
    else()
        set(OTEL_CPP_RUNTIME ${OTEL_CPP_PREFIX}/lib/libopentelemetry_proto${CMAKE_SHARED_LIBRARY_SUFFIX})
    endif()
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
set(COMMON_API_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/api/common/+opentelemetry)
set(TRACE_SDK_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/sdk/trace/+opentelemetry)
set(DEFAULT_EXPORTER_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/defaultSpanExporter.m)
set(OTLP_HTTP_EXPORTER_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpHttpSpanExporter.m)
set(OTLP_GRPC_EXPORTER_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpGrpcSpanExporter.m)

set(OTLP_EXPORTERS_DIR +opentelemetry/+exporters/+otlp)

install(DIRECTORY ${TRACE_API_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${CONTEXT_API_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${BAGGAGE_API_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${COMMON_API_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${TRACE_SDK_MATLAB_SOURCES} DESTINATION .)
install(FILES ${DEFAULT_EXPORTER_MATLAB_SOURCES} DESTINATION ${OTLP_EXPORTERS_DIR})
if(WITH_OTLP_HTTP)
    install(FILES ${OTLP_HTTP_EXPORTER_MATLAB_SOURCES} DESTINATION ${OTLP_EXPORTERS_DIR})
endif()
if(WITH_OTLP_GRPC)
    install(FILES ${OTLP_GRPC_EXPORTER_MATLAB_SOURCES} DESTINATION ${OTLP_EXPORTERS_DIR})
endif()

# Install dependent runtime libraries
set(LIBMEXCLASS_PROXY_INSTALLED_DIR +libmexclass/+proxy)
install(FILES ${OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES} DESTINATION ${LIBMEXCLASS_PROXY_INSTALLED_DIR})

# ##############################
# Subdirectories
# ##############################
if(WITH_EXAMPLES)
   add_subdirectory(examples)
endif()
