cmake_minimum_required(VERSION 3.9.0)

cmake_policy(SET CMP0074 NEW)

# set a platform name variable, needed to create separate directories for storing dependent libraries
if(WIN32)
   set(PLATFORM_NAME win64)
elseif(APPLE)
   # run uname -m to determine whether arm64 or x86_64
   exec_program(uname ARGS -m OUTPUT_VARIABLE MAC_HOST_SYSTEM)
   if(${MAC_HOST_SYSTEM} STREQUAL "arm64")
      set(PLATFORM_NAME maca64)
   elseif(${MAC_HOST_SYSTEM} STREQUAL "x86_64")
      set(PLATFORM_NAME maci64)
   endif()
else() # Linux
   set(PLATFORM_NAME glnxa64)
endif()

# ###########################
# vcpkg
# ###########################

include(FetchContent)

# check if VCPKG_ROOT is defined, which should point to an existing installation
# FETCH_VCPKG is a switch that can be defined to ignore VCPKG_ROOT
if(DEFINED ENV{VCPKG_ROOT} AND NOT DEFINED FETCH_VCPKG)
   # Autodetect vcpkg toolchain
   if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
       string(REPLACE "\\" "/" CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
   endif()
else()
   # VCPKG_ROOT not defined, get it using FetchContent

   if(DEFINED VCPKG_PREFIX)
       # download location specified
       string(REPLACE "\\" "/" VCPKG_PREFIX "${VCPKG_PREFIX}")
   else()
       set(VCPKG_PREFIX ${CMAKE_BINARY_DIR}/vcpkg)
   endif()

   set(VCPKG_FETCH_CONTENT_NAME vcpkg)
   set(VCPKG_GIT_REPOSITORY "https://github.com/microsoft/vcpkg.git")
   set(VCPKG_GIT_TAG "ce613c4")
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

# Define custom triplets for vcpkg
if(APPLE)
    # On Mac, there is a conflict between libcurl and the version in MATLAB, so 
    # use libcurl as a shared library and load the MATLAB version at runtime
    if(${MAC_HOST_SYSTEM} STREQUAL "arm64")
       set(VCPKG_OTEL_TRIPLET "arm64-osx-otel-matlab")
    elseif(${MAC_HOST_SYSTEM} STREQUAL "x86_64")
       set(VCPKG_OTEL_TRIPLET "x64-osx-otel-matlab")
    endif()
    set(VCPKG_OVERLAY_TRIPLETS ${CMAKE_SOURCE_DIR}/cmake/vcpkg_triplets)
    set(VCPKG_TARGET_TRIPLET ${VCPKG_OTEL_TRIPLET})
    set(TRIPLET_DEFINITIONS -DVCPKG_TARGET_TRIPLET=${VCPKG_TARGET_TRIPLET})
elseif(WIN32)
    # On Windows, we use a custom triplet to work around two issues.
    # First, there is a conflict between abseil_dll.dll and the version used by Simulink. 
    # The shared library doesn't seem ABI stable and different versions cannot be used interchangeably. 
    # To sidestep the problem, use static library.
    # Second, define a preprocessor macro _DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR to work around an invalid MEX file issue on GitHub
    # See https://github.com/mathworks/OpenTelemetry-Matlab/issues/130
    set(VCPKG_OVERLAY_TRIPLETS ${CMAKE_SOURCE_DIR}/cmake/vcpkg_triplets)
    set(VCPKG_TARGET_TRIPLET x64-windows-otel-matlab)
    set(TRIPLET_DEFINITIONS -DVCPKG_TARGET_TRIPLET=${VCPKG_TARGET_TRIPLET})
endif()

# ######################################
# Options
# ######################################

option(WITH_OTLP_HTTP "Whether to include the OTLP HTTP exporter" ON)
option(WITH_OTLP_GRPC "Whether to include the OTLP gRPC exporter" OFF)
option(WITH_OTLP_FILE "Whether to include the OTLP file exporter" OFF)
if(NOT WITH_OTLP_HTTP AND NOT WITH_OTLP_GRPC AND NOT WITH_OTLP_FILE)
    message(FATAL_ERROR "At least one of WITH_OTLP_HTTP, WITH_OTLP_GRPC, or WITH_OTLP_FILE must be ON")
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

# read version number
if(NOT DEFINED OTEL_MATLAB_VERSION)
    set(OTEL_MATLAB_VERSION 0.0.0)   # set to an invalid default if not defined
endif()

project(${CLIENT_PROJECT_NAME} VERSION ${OTEL_MATLAB_VERSION} LANGUAGES CXX C)

# set RPATH to enable libraries to find their dependencies
if(APPLE)
   set(CMAKE_INSTALL_RPATH @loader_path)
elseif(UNIX)
   set(CMAKE_INSTALL_RPATH "$ORIGIN")
endif()

# ###########################
# gRPC
# ###########################
if(WITH_OTLP_GRPC)
   set(GRPC_PACKAGE_NAME gRPC)
   set(GRPC_GIT_REPOSITORY "https://github.com/grpc/grpc.git")
   set(GRPC_GIT_TAG "4795c5e") 
   set(GRPC_PREFIX ${CMAKE_BINARY_DIR}/gRPC)
   set(GRPC_INSTALL_DIR ${GRPC_PREFIX}/install)
   set(GRPC_INSTALL_LIB_DIR ${GRPC_INSTALL_DIR}/lib)

   set(PATCHES_DIR ${CMAKE_SOURCE_DIR}/patches)
   if(WIN32)
       set(GRPC_PATCH_CMD "")
       set(GRPC_SHARED "-DBUILD_SHARED_LIBS=OFF")
   elseif(APPLE)
       set(GRPC_PATCH_CMD git apply ${PATCHES_DIR}/grpc-mac.patch)
       set(GRPC_SHARED "-DBUILD_SHARED_LIBS=ON")
   else()    # Linux
       set(GRPC_PATCH_CMD "")
       set(GRPC_SHARED "-DBUILD_SHARED_LIBS=ON")
   endif()

   if(WIN32)
       set(GRPC_LINK_LIBRARIES ${GRPC_INSTALL_LIB_DIR}/address_sorting.lib
	                   ${GRPC_INSTALL_LIB_DIR}/gpr.lib
	                   ${GRPC_INSTALL_LIB_DIR}/grpc++.lib
	                   ${GRPC_INSTALL_LIB_DIR}/grpc++_alts.lib
	                   ${GRPC_INSTALL_LIB_DIR}/grpc++_error_details.lib
	                   ${GRPC_INSTALL_LIB_DIR}/grpc++_reflection.lib
	                   ${GRPC_INSTALL_LIB_DIR}/grpc++_unsecure.lib
	                   ${GRPC_INSTALL_LIB_DIR}/grpc.lib
	                   ${GRPC_INSTALL_LIB_DIR}/grpc_authorization_provider.lib
	                   ${GRPC_INSTALL_LIB_DIR}/grpc_plugin_support.lib
	                   ${GRPC_INSTALL_LIB_DIR}/grpc_unsecure.lib
	                   ${GRPC_INSTALL_LIB_DIR}/grpcpp_channelz.lib
	                   ${GRPC_INSTALL_LIB_DIR}/upb_base_lib.lib
	                   ${GRPC_INSTALL_LIB_DIR}/upb_json_lib.lib
	                   ${GRPC_INSTALL_LIB_DIR}/upb_mem_lib.lib
	                   ${GRPC_INSTALL_LIB_DIR}/upb_message_lib.lib
	                   ${GRPC_INSTALL_LIB_DIR}/upb_textformat_lib.lib
	                   ${GRPC_INSTALL_LIB_DIR}/utf8_range_lib.lib)
    elseif(APPLE)
       set(GRPC_LINK_LIBRARIES ${GRPC_INSTALL_LIB_DIR}/libaddress_sorting.dylib
	                   ${GRPC_INSTALL_LIB_DIR}/libgpr.dylib
	                   ${GRPC_INSTALL_LIB_DIR}/libgrpc++.dylib
	                   ${GRPC_INSTALL_LIB_DIR}/libgrpc++_unsecure.dylib
	                   ${GRPC_INSTALL_LIB_DIR}/libgrpc.dylib
	                   ${GRPC_INSTALL_LIB_DIR}/libgrpc_unsecure.dylib
	                   ${GRPC_INSTALL_LIB_DIR}/libupb_base_lib.dylib
	                   ${GRPC_INSTALL_LIB_DIR}/libupb_json_lib.dylib
	                   ${GRPC_INSTALL_LIB_DIR}/libupb_mem_lib.dylib
	                   ${GRPC_INSTALL_LIB_DIR}/libupb_message_lib.dylib
	                   ${GRPC_INSTALL_LIB_DIR}/libupb_textformat_lib.dylib
	                   ${GRPC_INSTALL_LIB_DIR}/libutf8_range_lib.dylib)
    else()
       set(GRPC_LINK_LIBRARIES ${GRPC_INSTALL_LIB_DIR}/libgrpc++${CMAKE_SHARED_LIBRARY_SUFFIX})
    endif()

   include(ExternalProject)
   ExternalProject_Add(
       ${GRPC_PACKAGE_NAME}
       GIT_REPOSITORY ${GRPC_GIT_REPOSITORY}
       GIT_TAG ${GRPC_GIT_TAG}
       GIT_SUBMODULES_RECURSE OFF
       PREFIX ${GRPC_PREFIX}
       UPDATE_DISCONNECTED 1
       PATCH_COMMAND ${GRPC_PATCH_CMD}
       CMAKE_ARGS -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_RPATH=${CMAKE_INSTALL_RPATH} ${GRPC_SHARED} -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DCMAKE_CROSSCOMPILING=OFF -DgRPC_ZLIB_PROVIDER=package -DgRPC_ABSL_PROVIDER=package -DgRPC_PROTOBUF_PROVIDER=package -DgRPC_RE2_PROVIDER=package -DgRPC_SSL_PROVIDER=package -DgRPC_CARES_PROVIDER=package -DgRPC_BUILD_GRPC_CSHARP_PLUGIN=OFF -DgRPC_BUILD_GRPC_NODE_PLUGIN=OFF -DgRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=OFF -DgRPC_BUILD_GRPC_PHP_PLUGIN=OFF -DgRPC_BUILD_GRPC_PYTHON_PLUGIN=OFF -DgRPC_BUILD_GRPC_RUBY_PLUGIN=OFF -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} -DVCPKG_INSTALLED_DIR=${VCPKG_INSTALLED_DIR} ${TRIPLET_DEFINITIONS}
       BUILD_BYPRODUCTS ${GRPC_LINK_LIBRARIES}
       INSTALL_DIR ${GRPC_INSTALL_DIR}
       INSTALL_COMMAND ${CMAKE_COMMAND} --install . --prefix ${GRPC_INSTALL_DIR} --config $<CONFIG>
   )

   if(UNIX AND NOT APPLE AND NOT CYGWIN)
       # needed for running protoc as part of the opentelemetry-cpp build
       set(GRPC_LD_LIBRARY_PATH_ENV "LD_LIBRARY_PATH=${GRPC_INSTALL_LIB_DIR}")
   endif()

endif()

# ######################################
# libmexclass 
# ######################################

set(LIBMEXCLASS_FETCH_CONTENT_NAME libmexclass)

set(LIBMEXCLASS_FETCH_CONTENT_GIT_REPOSITORY "https://github.com/mathworks/libmexclass.git")

set(LIBMEXCLASS_FETCH_CONTENT_GIT_TAG "3a3b581") 

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

# Determine OTEL_CPP_PREFIX
if(DEFINED OTEL_CPP_INSTALLED_DIR)
   # Set OTEL_CPP_INSTALLED_DIR to use a pre-installed OpenTelemetry-cpp
   # It should point to the installed location
   string(REPLACE "\\" "/" OTEL_CPP_PREFIX ${OTEL_CPP_INSTALLED_DIR})
elseif(DEFINED OTEL_CPP_PREFIX)
   # Set OTEL_CPP_PREFIX to specify an install location of the automatically 
   # downloaded and built OpenTelemetry-cpp, instead of using the default 
   # location with the build directory. This can preserve the OpenTelemetry-cpp
   # install even if the build directory is removed.
     string(REPLACE "\\" "/" OTEL_CPP_PREFIX ${OTEL_CPP_PREFIX})
else()
     set(OTEL_CPP_PREFIX ${CMAKE_BINARY_DIR}/otel-cpp)
endif()

set(OTEL_CPP_LIBRARIES ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_common${CMAKE_STATIC_LIBRARY_SUFFIX}
	${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_otlp_recordable${CMAKE_STATIC_LIBRARY_SUFFIX}
        ${OTEL_CPP_PREFIX}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}opentelemetry_proto${CMAKE_STATIC_LIBRARY_SUFFIX}
	${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_resources${CMAKE_STATIC_LIBRARY_SUFFIX}
	${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_trace${CMAKE_STATIC_LIBRARY_SUFFIX}
	${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_version${CMAKE_STATIC_LIBRARY_SUFFIX}
	${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_logs${CMAKE_STATIC_LIBRARY_SUFFIX}
	${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_metrics${CMAKE_STATIC_LIBRARY_SUFFIX})
if(WITH_OTLP_HTTP)
    set(OTEL_CPP_LIBRARIES ${OTEL_CPP_LIBRARIES} ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_http${CMAKE_STATIC_LIBRARY_SUFFIX}
	    ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_http_client${CMAKE_STATIC_LIBRARY_SUFFIX}
	    ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_http_metric${CMAKE_STATIC_LIBRARY_SUFFIX}
	    ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_http_log${CMAKE_STATIC_LIBRARY_SUFFIX}
	    ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_http_client_curl${CMAKE_STATIC_LIBRARY_SUFFIX})
endif()
if(WITH_OTLP_GRPC)
    set(OTEL_CPP_LIBRARIES ${OTEL_CPP_LIBRARIES} ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_grpc${CMAKE_STATIC_LIBRARY_SUFFIX}
	    ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_grpc_client${CMAKE_STATIC_LIBRARY_SUFFIX}
	    ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_grpc_metrics${CMAKE_STATIC_LIBRARY_SUFFIX}
	    ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_grpc_log${CMAKE_STATIC_LIBRARY_SUFFIX}
            ${OTEL_CPP_PREFIX}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}opentelemetry_proto_grpc${CMAKE_STATIC_LIBRARY_SUFFIX})
endif()
if(WITH_OTLP_FILE)
    set(OTEL_CPP_LIBRARIES ${OTEL_CPP_LIBRARIES} ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_file${CMAKE_STATIC_LIBRARY_SUFFIX}
	    ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_file_client${CMAKE_STATIC_LIBRARY_SUFFIX}
	    ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_file_metric${CMAKE_STATIC_LIBRARY_SUFFIX}
	    ${OTEL_CPP_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}opentelemetry_exporter_otlp_file_log${CMAKE_STATIC_LIBRARY_SUFFIX})
endif()

if(NOT DEFINED OTEL_CPP_INSTALLED_DIR)
   # No installed location supplied. Fetch it as an external project
   include(ExternalProject)
   set(OTEL_CPP_PROJECT_NAME opentelemetry-cpp)
   set(OTEL_CPP_GIT_REPOSITORY "https://github.com/open-telemetry/opentelemetry-cpp.git")
   set(OTEL_CPP_GIT_TAG "a7b1008")

   set(OTEL_CPP_CXX_STANDARD 14)

   # The synchronous gauge metric instrument is only defined in ABI version 2
   set(OTEL_CPP_ABI_VERSION OPENTELEMETRY_ABI_VERSION_NO=2)

   set(PATCHES_DIR ${CMAKE_SOURCE_DIR}/patches)
   set(OTEL_CPP_PATCH_CMD "")
   if(WIN32 AND NOT SKIP_OTEL_CPP_PATCH)
       # Windows patch to add a preprocessor definition _DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR
       # See https://github.com/mathworks/OpenTelemetry-Matlab/issues/130
       set(OTEL_CPP_PATCH_CMD git apply ${PATCHES_DIR}/otel-cpp-windows.patch)
   endif()

   if(WITH_OTLP_GRPC)
       set(OTEL_CPP_DEPENDS ${GRPC_PACKAGE_NAME})
   endif()

   if(WIN32 OR APPLE)
       # Windows and Mac use the default build command
       # Note: examples are temporarily turned off (-DWITH_EXAMPLES=OFF) due to a build issue that is now fixed in #3284
       # Renable examples after pulling in the fix
       ExternalProject_Add(
           ${OTEL_CPP_PROJECT_NAME}
           GIT_REPOSITORY ${OTEL_CPP_GIT_REPOSITORY}
           GIT_TAG ${OTEL_CPP_GIT_TAG}
           PREFIX ${OTEL_CPP_PREFIX}
           DEPENDS ${OTEL_CPP_DEPENDS}
           UPDATE_DISCONNECTED 1
           PATCH_COMMAND ${OTEL_CPP_PATCH_CMD}
           CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_RPATH=${CMAKE_INSTALL_RPATH} -DgRPC_DIR=${GRPC_INSTALL_LIB_DIR}/cmake/grpc -DWITH_ABI_VERSION_1=OFF -DWITH_ABI_VERSION_2=ON -DWITH_OTLP_HTTP=${WITH_OTLP_HTTP} -DWITH_OTLP_GRPC=${WITH_OTLP_GRPC} -DWITH_OTLP_FILE=${WITH_OTLP_FILE} -DWITH_EXAMPLES=OFF -DBUILD_TESTING=OFF -DWITH_BENCHMARK=OFF -DOPENTELEMETRY_INSTALL=ON -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} -DCMAKE_CXX_STANDARD=${OTEL_CPP_CXX_STANDARD} -DVCPKG_INSTALLED_DIR=${VCPKG_INSTALLED_DIR} ${TRIPLET_DEFINITIONS}
           BUILD_BYPRODUCTS ${OTEL_CPP_LIBRARIES}
           INSTALL_DIR ${OTEL_CPP_PREFIX}
           INSTALL_COMMAND ${CMAKE_COMMAND} --install . --prefix ${OTEL_CPP_PREFIX} --config $<CONFIG>
       )
   else()
       # Linux use a custom build command
       # Note: examples are temporarily turned off (-DWITH_EXAMPLES=OFF) due to a build issue that is now fixed in #3284
       # Renable examples after pulling in the fix
       ExternalProject_Add(
           ${OTEL_CPP_PROJECT_NAME}
           GIT_REPOSITORY ${OTEL_CPP_GIT_REPOSITORY}
           GIT_TAG ${OTEL_CPP_GIT_TAG}
           PREFIX ${OTEL_CPP_PREFIX}
           DEPENDS ${OTEL_CPP_DEPENDS}
           UPDATE_DISCONNECTED 1
           PATCH_COMMAND ${OTEL_CPP_PATCH_CMD}
           CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER} -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER} -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_RPATH=${CMAKE_INSTALL_RPATH} -DgRPC_DIR=${GRPC_INSTALL_LIB_DIR}/cmake/grpc -DWITH_ABI_VERSION_1=OFF -DWITH_ABI_VERSION_2=ON -DWITH_OTLP_HTTP=${WITH_OTLP_HTTP} -DWITH_OTLP_GRPC=${WITH_OTLP_GRPC} -DWITH_OTLP_FILE=${WITH_OTLP_FILE} -DWITH_EXAMPLES=OFF -DBUILD_TESTING=OFF -DWITH_BENCHMARK=OFF -DOPENTELEMETRY_INSTALL=ON -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} -DCMAKE_CXX_STANDARD=${OTEL_CPP_CXX_STANDARD} -DVCPKG_INSTALLED_DIR=${VCPKG_INSTALLED_DIR} ${TRIPLET_DEFINITIONS}
           BUILD_COMMAND ${CMAKE_COMMAND} -E env ${GRPC_LD_LIBRARY_PATH_ENV} ${CMAKE_MAKE_PROGRAM}
           BUILD_BYPRODUCTS ${OTEL_CPP_LIBRARIES}
           INSTALL_DIR ${OTEL_CPP_PREFIX}
           INSTALL_COMMAND ${CMAKE_COMMAND} --install . --prefix ${OTEL_CPP_PREFIX} --config $<CONFIG>
       )
   endif()

endif()


# ###########################
# OpenTelemetry Proxy Library
# ###########################


set(OPENTELEMETRY_PROXY_LIBRARY_NAME "OtelMatlabProxy")

find_package(Matlab REQUIRED)
find_package(Protobuf REQUIRED)
find_package(nlohmann_json REQUIRED)
if(WIN32 OR APPLE)
    find_package(ZLIB REQUIRED)
endif()

if(WITH_OTLP_HTTP)
    find_package(CURL REQUIRED)
endif()

if(WITH_OTLP_GRPC)
    find_package(absl REQUIRED)
    find_package(c-ares REQUIRED)
    find_package(re2 REQUIRED)
    find_package(OpenSSL REQUIRED COMPONENTS SSL Crypto)
endif()

set(TRACE_API_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/trace/include)
set(METRICS_API_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/metrics/include)
set(LOGS_API_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/logs/include)
set(CONTEXT_API_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/context/include) 
set(BAGGAGE_API_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/baggage/include) 
set(COMMON_API_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/common/include) 
set(TRACE_SDK_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/trace/include)
set(METRICS_SDK_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/metrics/include)
set(LOGS_SDK_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/logs/include)
set(COMMON_SDK_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/common/include)
set(OTLP_EXPORTER_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/include)
set(OPENTELEMETRY_PROXY_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR} ${TRACE_API_INCLUDE_DIR} ${METRICS_API_INCLUDE_DIR} ${LOGS_API_INCLUDE_DIR} ${CONTEXT_API_INCLUDE_DIR} ${BAGGAGE_API_INCLUDE_DIR} ${COMMON_API_INCLUDE_DIR} ${TRACE_SDK_INCLUDE_DIR} ${METRICS_SDK_INCLUDE_DIR} ${LOGS_SDK_INCLUDE_DIR} ${COMMON_SDK_INCLUDE_DIR} ${OTLP_EXPORTER_INCLUDE_DIR} ${OTEL_CPP_PREFIX}/include ${Matlab_INCLUDE_DIRS})

set(OPENTELEMETRY_PROXY_FACTORY_CLASS_NAME OtelMatlabProxyFactory)
set(OPENTELEMETRY_PROXY_FACTORY_SOURCES_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(TRACE_API_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/trace/src)
set(METRICS_API_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/metrics/src)
set(LOGS_API_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/logs/src)
set(CONTEXT_API_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/context/src)
set(BAGGAGE_API_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/baggage/src)
set(COMMON_API_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/api/common/src)
set(TRACE_SDK_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/trace/src)
set(METRICS_SDK_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/metrics/src)
set(LOGS_SDK_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/logs/src)
set(COMMON_SDK_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/sdk/common/src)
set(OTLP_EXPORTER_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/src)
set(OPENTELEMETRY_PROXY_SOURCES
    ${OPENTELEMETRY_PROXY_FACTORY_SOURCES_DIR}/${OPENTELEMETRY_PROXY_FACTORY_CLASS_NAME}.cpp
    ${TRACE_API_SOURCE_DIR}/TracerProviderProxy.cpp
    ${TRACE_API_SOURCE_DIR}/TracerProxy.cpp
    ${TRACE_API_SOURCE_DIR}/SpanProxy.cpp
    ${TRACE_API_SOURCE_DIR}/SpanContextProxy.cpp
    ${COMMON_API_SOURCE_DIR}/attribute.cpp
    ${METRICS_API_SOURCE_DIR}/MeterProviderProxy.cpp
    ${METRICS_API_SOURCE_DIR}/MeterProxy.cpp
    ${METRICS_API_SOURCE_DIR}/CounterProxy.cpp
    ${METRICS_API_SOURCE_DIR}/UpDownCounterProxy.cpp
    ${METRICS_API_SOURCE_DIR}/HistogramProxy.cpp
    ${METRICS_API_SOURCE_DIR}/GaugeProxy.cpp
    ${METRICS_API_SOURCE_DIR}/SynchronousInstrumentProxyFactory.cpp
    ${METRICS_API_SOURCE_DIR}/MeasurementFetcher.cpp
    ${METRICS_API_SOURCE_DIR}/AsynchronousInstrumentProxy.cpp
    ${METRICS_API_SOURCE_DIR}/AsynchronousInstrumentProxyFactory.cpp
    ${LOGS_API_SOURCE_DIR}/LoggerProviderProxy.cpp
    ${LOGS_API_SOURCE_DIR}/LoggerProxy.cpp
    ${CONTEXT_API_SOURCE_DIR}/TextMapPropagatorProxy.cpp
    ${CONTEXT_API_SOURCE_DIR}/CompositePropagatorProxy.cpp
    ${CONTEXT_API_SOURCE_DIR}/TextMapCarrierProxy.cpp
    ${CONTEXT_API_SOURCE_DIR}/ContextProxy.cpp
    ${BAGGAGE_API_SOURCE_DIR}/BaggageProxy.cpp
    ${TRACE_SDK_SOURCE_DIR}/TracerProviderProxy.cpp
    ${TRACE_SDK_SOURCE_DIR}/SimpleSpanProcessorProxy.cpp
    ${TRACE_SDK_SOURCE_DIR}/BatchSpanProcessorProxy.cpp
    ${TRACE_SDK_SOURCE_DIR}/ParentBasedSamplerProxy.cpp
    ${METRICS_SDK_SOURCE_DIR}/MeterProviderProxy.cpp
    ${METRICS_SDK_SOURCE_DIR}/ViewProxy.cpp
    ${METRICS_SDK_SOURCE_DIR}/PeriodicExportingMetricReaderProxy.cpp
    ${LOGS_SDK_SOURCE_DIR}/LoggerProviderProxy.cpp
    ${LOGS_SDK_SOURCE_DIR}/SimpleLogRecordProcessorProxy.cpp
    ${LOGS_SDK_SOURCE_DIR}/BatchLogRecordProcessorProxy.cpp
    ${COMMON_SDK_SOURCE_DIR}/resource.cpp
    ${COMMON_SDK_SOURCE_DIR}/InternalLogHandlerProxy.cpp)
if(WITH_OTLP_HTTP)
    set(OPENTELEMETRY_PROXY_SOURCES 
    ${OPENTELEMETRY_PROXY_SOURCES} 
    ${OTLP_EXPORTER_SOURCE_DIR}/OtlpHttpSpanExporterProxy.cpp
    ${OTLP_EXPORTER_SOURCE_DIR}/OtlpHttpMetricExporterProxy.cpp
    ${OTLP_EXPORTER_SOURCE_DIR}/OtlpHttpLogRecordExporterProxy.cpp)
endif()
if(WITH_OTLP_GRPC)
    set(OPENTELEMETRY_PROXY_SOURCES 
    ${OPENTELEMETRY_PROXY_SOURCES}
    ${OTLP_EXPORTER_SOURCE_DIR}/OtlpGrpcSpanExporterProxy.cpp
    ${OTLP_EXPORTER_SOURCE_DIR}/OtlpGrpcMetricExporterProxy.cpp
    ${OTLP_EXPORTER_SOURCE_DIR}/OtlpGrpcLogRecordExporterProxy.cpp)
endif()
if(WITH_OTLP_FILE)
    set(OPENTELEMETRY_PROXY_SOURCES 
    ${OPENTELEMETRY_PROXY_SOURCES} 
    ${OTLP_EXPORTER_SOURCE_DIR}/OtlpFileSpanExporterProxy.cpp
    ${OTLP_EXPORTER_SOURCE_DIR}/OtlpFileMetricExporterProxy.cpp
    ${OTLP_EXPORTER_SOURCE_DIR}/OtlpFileLogRecordExporterProxy.cpp)
endif()

if(WIN32)
    # Add a preprocessor definition _DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR to fix an invalid mex file issue on Windows.
    # See https://github.com/mathworks/OpenTelemetry-Matlab/issues/130
    add_compile_definitions(_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR)
endif()

libmexclass_client_add_proxy_library(
    NAME ${OPENTELEMETRY_PROXY_LIBRARY_NAME}
    SOURCES ${OPENTELEMETRY_PROXY_SOURCES}
    INCLUDE_DIRS ${OPENTELEMETRY_PROXY_INCLUDE_DIRS}
)

if(NOT DEFINED OTEL_CPP_INSTALLED_DIR)
    add_dependencies(${OPENTELEMETRY_PROXY_LIBRARY_NAME} ${OTEL_CPP_PROJECT_NAME})
endif()

# Additional compiler flags for HTTP/gRPC/file exporters
if(WITH_OTLP_HTTP)
    target_compile_definitions(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE WITH_OTLP_HTTP)
endif()

if(WITH_OTLP_GRPC)
    target_compile_definitions(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE WITH_OTLP_GRPC)
endif()

if(WITH_OTLP_FILE)
    target_compile_definitions(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE WITH_OTLP_FILE)
endif()

target_compile_definitions(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE ${OTEL_CPP_ABI_VERSION})

# pass in version number
target_compile_definitions(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE OTEL_MATLAB_VERSION="${OTEL_MATLAB_VERSION}")
if(WIN32)
    # On Windows, suppress a compiler warning about deprecation of result_of
    target_compile_definitions(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PUBLIC _SILENCE_CXX17_RESULT_OF_DEPRECATION_WARNING)
endif()

# link against OpenTelemetry-cpp libraries and their dependencies
set(OPENTELEMETRY_PROXY_LINK_LIBRARIES ${OTEL_CPP_LIBRARIES} protobuf::libprotobuf ${Matlab_MEX_LIBRARY})
if(WITH_OTLP_HTTP)
    set(OPENTELEMETRY_PROXY_LINK_LIBRARIES ${OPENTELEMETRY_PROXY_LINK_LIBRARIES} ${CURL_LIBRARIES})
endif()
if(WITH_OTLP_GRPC)
    set(OPENTELEMETRY_PROXY_LINK_LIBRARIES ${OPENTELEMETRY_PROXY_LINK_LIBRARIES} ${GRPC_LINK_LIBRARIES} absl::synchronization
	    absl::random_random ZLIB::ZLIB re2::re2 c-ares::cares OpenSSL::SSL OpenSSL::Crypto)
endif()

target_link_libraries(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE ${OPENTELEMETRY_PROXY_LINK_LIBRARIES})

# On Linux, when linking with certain static libraries, need to force include entire archive to avoid the linker mistakenly leaving out symbols
if(UNIX AND NOT APPLE AND NOT CYGWIN)
    set(OPENTELEMETRY_PROXY_LINK_OPTIONS -Wl,--whole-archive 
	"${OTEL_CPP_PREFIX}/lib/libopentelemetry_trace.a"
	"${OTEL_CPP_PREFIX}/lib/libopentelemetry_logs.a"
	"${OTEL_CPP_PREFIX}/lib/libopentelemetry_common.a"
	"${OTEL_CPP_PREFIX}/lib/libopentelemetry_otlp_recordable.a"
	"${OTEL_CPP_PREFIX}/lib/libopentelemetry_proto.a"
        ${ABSL_LIBRARIES} -Wl,--no-whole-archive)
    target_link_options(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE ${OPENTELEMETRY_PROXY_LINK_OPTIONS})
endif()

# Use C++17 
target_compile_features(${OPENTELEMETRY_PROXY_LIBRARY_NAME} PRIVATE cxx_std_17)

# runtime dependent libraries
# gRPC runtime libraries for non-Windows are listed further below in the installation section
if(WIN32)
    # The TARGET_FILE generator command is somehow returning the .lib file instead of .dll for Zlib. 
    # As a result, we have to hardcode those library names instead.
    set(ZLIB_DLL $<$<CONFIG:Debug>:zlibd1.dll>$<$<CONFIG:Release>:zlib1.dll>)
    set(OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES $<TARGET_FILE_DIR:ZLIB::ZLIB>/../bin/${ZLIB_DLL})

    if(WITH_OTLP_HTTP)
	set(OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES ${OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES}
            $<TARGET_FILE:CURL::libcurl_shared>)
    endif()

    if(WITH_OTLP_GRPC)
	# The TARGET_FILE generator command fails to return the DLL libraries for OpenSSL.
        # As a result, we have to hardcode those library names instead.
	set(OPENSSL_DLL libssl-3-x64.dll)
	set(OPENSSL_CRYPTO_DLL libcrypto-3-x64.dll)
	set(OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES ${OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES}
	    $<TARGET_FILE_DIR:OpenSSL::SSL>/../bin/${OPENSSL_DLL}
	    $<TARGET_FILE_DIR:OpenSSL::SSL>/../bin/${OPENSSL_CRYPTO_DLL})
    endif()
elseif(APPLE)
    set(OTEL_CPP_RUNTIME $<TARGET_FILE:ZLIB::ZLIB> 
        $<TARGET_FILE_DIR:ZLIB::ZLIB>/libz.${ZLIB_MAJOR_VERSION}${CMAKE_SHARED_LIBRARY_SUFFIX}
        $<TARGET_FILE_DIR:ZLIB::ZLIB>/libz.${ZLIB_VERSION}${CMAKE_SHARED_LIBRARY_SUFFIX})
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

if(APPLE)
    set_target_properties(${OPENTELEMETRY_MEX_GATEWAY_NAME} PROPERTIES INSTALL_RPATH "@loader_path;@loader_path/../../lib/${PLATFORM_NAME}")
elseif(UNIX)
    set_target_properties(${OPENTELEMETRY_MEX_GATEWAY_NAME} PROPERTIES INSTALL_RPATH "$ORIGIN;$ORIGIN/../../lib/${PLATFORM_NAME}")
endif()

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
set(METRICS_API_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/api/metrics/+opentelemetry)
set(LOGS_API_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/api/logs/+opentelemetry)
set(CONTEXT_API_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/api/context/+opentelemetry)
set(BAGGAGE_API_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/api/baggage/+opentelemetry)
set(COMMON_API_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/api/common/+opentelemetry)
set(TRACE_SDK_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/sdk/trace/+opentelemetry)
set(METRICS_SDK_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/sdk/metrics/+opentelemetry)
set(LOGS_SDK_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/sdk/logs/+opentelemetry)
set(COMMON_SDK_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/sdk/common/+opentelemetry)
set(AUTO_INSTRUMENTATION_MATLAB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/auto-instrumentation/+opentelemetry)
set(EXPORTER_MATLAB_SOURCES 
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/defaultSpanExporter.m
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/defaultMetricExporter.m
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/defaultLogRecordExporter.m
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpValidator.m)
set(OTLP_HTTP_EXPORTER_MATLAB_SOURCES 
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpHttpSpanExporter.m
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpHttpMetricExporter.m
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpHttpLogRecordExporter.m
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpHttpValidator.m)
set(OTLP_GRPC_EXPORTER_MATLAB_SOURCES 
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpGrpcSpanExporter.m
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpGrpcMetricExporter.m
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpGrpcLogRecordExporter.m
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpGrpcValidator.m)
set(OTLP_FILE_EXPORTER_MATLAB_SOURCES 
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpFileSpanExporter.m
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpFileMetricExporter.m
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpFileLogRecordExporter.m
    ${CMAKE_CURRENT_SOURCE_DIR}/exporters/otlp/+opentelemetry/+exporters/+otlp/OtlpFileValidator.m)
set(OTLP_MISC_FILES ${CMAKE_CURRENT_SOURCE_DIR}/LICENSE)

set(OTLP_EXPORTERS_DIR +opentelemetry/+exporters/+otlp)

install(DIRECTORY ${TRACE_API_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${METRICS_API_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${LOGS_API_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${CONTEXT_API_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${BAGGAGE_API_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${COMMON_API_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${TRACE_SDK_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${METRICS_SDK_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${LOGS_SDK_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${COMMON_SDK_MATLAB_SOURCES} DESTINATION .)
install(DIRECTORY ${AUTO_INSTRUMENTATION_MATLAB_SOURCES} DESTINATION .)
install(FILES ${EXPORTER_MATLAB_SOURCES} DESTINATION ${OTLP_EXPORTERS_DIR})
if(WITH_OTLP_HTTP)
    install(FILES ${OTLP_HTTP_EXPORTER_MATLAB_SOURCES} DESTINATION ${OTLP_EXPORTERS_DIR})
endif()
if(WITH_OTLP_GRPC)
    install(FILES ${OTLP_GRPC_EXPORTER_MATLAB_SOURCES} DESTINATION ${OTLP_EXPORTERS_DIR})
endif()
if(WITH_OTLP_FILE)
    install(FILES ${OTLP_FILE_EXPORTER_MATLAB_SOURCES} DESTINATION ${OTLP_EXPORTERS_DIR})
endif()
# Install license. The only reason it is needed is to work around a packaging bug where if 
# all files are in packages (+xxx directories), matlab.addons.toolbox.packageToolbox refuses to add the 
# toolbox path into MATLAB path. This issue is fixed in R2024a
install(FILES ${OTLP_MISC_FILES} DESTINATION .)

# Macro to install a library and then rename it to shorten its version. The renaming is intended to 
# work around an issue in matlab.addons.toolbox.packagetoolbox that omits symlinks from the resulting 
# mltbx package. Many libraries ship symlinks with shortened version numbers. The renaming here 
# effectively converts symlinks into their targets.
# Accepts base name, full version, and short version
macro(install_and_shorten_version base full_version short_version)
    if(APPLE)
        # macOS: version before extension
        set(SRC_FILE "${base}.${full_version}${CMAKE_SHARED_LIBRARY_SUFFIX}")
        set(DEST_FILE "${base}.${short_version}${CMAKE_SHARED_LIBRARY_SUFFIX}")
    else()
        # Linux: version after extension
        set(SRC_FILE "${base}${CMAKE_SHARED_LIBRARY_SUFFIX}.${full_version}")
        set(DEST_FILE "${base}${CMAKE_SHARED_LIBRARY_SUFFIX}.${short_version}")
    endif()

    # Install the original file
    install(FILES "${GRPC_INSTALL_LIB_DIR}/${SRC_FILE}" DESTINATION "${DEPENDENT_RUNTIME_INSTALLED_DIR}")

    # Rename after installation
    install(CODE "file(RENAME \"${CMAKE_INSTALL_PREFIX}/${DEPENDENT_RUNTIME_INSTALLED_DIR}/${SRC_FILE}\" \"${CMAKE_INSTALL_PREFIX}/${DEPENDENT_RUNTIME_INSTALLED_DIR}/${DEST_FILE}\")")
endmacro()

# Install dependent runtime libraries
set(LIBMEXCLASS_PACKAGE_DIRECTORY +libmexclass/+proxy)
if(WIN32)
    # On Windows, install all libraries in the same directory because of the lack of a settable rpath
    set(DEPENDENT_RUNTIME_INSTALLED_DIR ${LIBMEXCLASS_PACKAGE_DIRECTORY})
else()
    # On non-Windows platform, install dependent libraries in a platform specific directory so that
    # they won't get overwritten when packaged
    set(DEPENDENT_RUNTIME_INSTALLED_DIR lib/${PLATFORM_NAME})
endif()
install(CODE "file(MAKE_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${DEPENDENT_RUNTIME_INSTALLED_DIR})")
install(FILES ${OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES} DESTINATION ${DEPENDENT_RUNTIME_INSTALLED_DIR})
if(UNIX)
    if(WITH_OTLP_GRPC)
        # Install gRPC shared libraries

	# Loop through gRPC and dependent libraries
        set(GRPC_FULL_VERSION "41.0.0")
        set(GRPC_SHORT_VERSION "41")
        foreach(grpcfile IN ITEMS
            libaddress_sorting
            libgpr
            libgrpc
            libgrpc_unsecure
            libupb_base_lib
            libupb_json_lib
            libupb_mem_lib
            libupb_message_lib
            libupb_textformat_lib
            libutf8_range_lib
        )
            install_and_shorten_version(${grpcfile} ${GRPC_FULL_VERSION} ${GRPC_SHORT_VERSION})
        endforeach()

	# Loop through libgrpc++ libraries (different version scheme)
        set(GRPCPP_FULL_VERSION "1.64.2")
        set(GRPCPP_SHORT_VERSION "1.64")
        foreach(grpcppfile IN ITEMS
            libgrpc++
            libgrpc++_unsecure
        )
            install_and_shorten_version(${grpcppfile} ${GRPCPP_FULL_VERSION} ${GRPCPP_SHORT_VERSION})
        endforeach()
    endif()

    # Move any shared libraries to platform specific directories, so that they won't overwrite each other
    set(LIBMEXCLASS_LIBRARY_NAME mexclass)
    set(LIBMEXCLASS_LIBRARY ${LIBMEXCLASS_LIBRARY_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX})
    set(OPENTELEMETRY_PROXY_LIBRARY ${OPENTELEMETRY_PROXY_LIBRARY_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX})
    install(CODE "file(RENAME \"${CMAKE_INSTALL_PREFIX}/${LIBMEXCLASS_PACKAGE_DIRECTORY}/lib${LIBMEXCLASS_LIBRARY}\" \"${CMAKE_INSTALL_PREFIX}/${DEPENDENT_RUNTIME_INSTALLED_DIR}/lib${LIBMEXCLASS_LIBRARY}\")")
    install(CODE "file(RENAME \"${CMAKE_INSTALL_PREFIX}/${LIBMEXCLASS_PACKAGE_DIRECTORY}/lib${OPENTELEMETRY_PROXY_LIBRARY}\" \"${CMAKE_INSTALL_PREFIX}/${DEPENDENT_RUNTIME_INSTALLED_DIR}/lib${OPENTELEMETRY_PROXY_LIBRARY}\")")
endif()

# ##############################
# Subdirectories
# ##############################
if(WITH_EXAMPLES)
   add_subdirectory(examples)
endif()


