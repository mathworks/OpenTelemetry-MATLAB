# Set this option to ON if running in GitHub Actions workflows
option(USE_BATCH_FOR_MCC "Running on GitHub Actions workflows requires calling mcc using matlab-batch due to licensing constraints." OFF)

# C++ target
set(CONTEXTPROP_EXAMPLE_CPP_TARGET contextprop_example_client)
add_executable(${CONTEXTPROP_EXAMPLE_CPP_TARGET} cpp/client.cc)
if(NOT DEFINED OTEL_CPP_INSTALLED_DIR)
    add_dependencies(${CONTEXTPROP_EXAMPLE_CPP_TARGET} ${OTEL_CPP_PROJECT_NAME})
endif()

# Specify the ABI version, include directories, and libraries of otel-cpp. The C++ code in this example directly calls otel-cpp functions.
target_compile_definitions(${CONTEXTPROP_EXAMPLE_CPP_TARGET} PRIVATE ${OTEL_CPP_ABI_VERSION})
target_include_directories(${CONTEXTPROP_EXAMPLE_CPP_TARGET} PRIVATE ${OTEL_CPP_PREFIX}/include)
target_link_libraries(${CONTEXTPROP_EXAMPLE_CPP_TARGET} PRIVATE ${OPENTELEMETRY_PROXY_LINK_LIBRARIES})
if(UNIX AND NOT APPLE AND NOT CYGWIN)
    target_link_options(${CONTEXTPROP_EXAMPLE_CPP_TARGET} PRIVATE ${OPENTELEMETRY_PROXY_LINK_OPTIONS})
elseif(APPLE)
    set_target_properties(${CONTEXTPROP_EXAMPLE_CPP_TARGET} PROPERTIES BUILD_RPATH "${CMAKE_INSTALL_PREFIX}/${LIBMEXCLASS_PROXY_INSTALLED_DIR}")
endif()
# use the same C++ standard as OpenTelemetry-cpp if known, otherwise just use the default C++14
if(NOT DEFINED OTEL_CPP_INSTALLED_DIR)
    target_compile_features(${CONTEXTPROP_EXAMPLE_CPP_TARGET} PRIVATE cxx_std_${OTEL_CPP_CXX_STANDARD})
else()
    target_compile_features(${CONTEXTPROP_EXAMPLE_CPP_TARGET} PRIVATE cxx_std_14)
endif()

# MATLAB target
find_package(Matlab REQUIRED COMPONENTS MCC_COMPILER MAIN_PROGRAM)

set(CONTEXTPROP_EXAMPLE_DEPLOYNAME mymagic)
set(CONTEXTPROP_EXAMPLE_MATLAB_TARGET ${CONTEXTPROP_EXAMPLE_DEPLOYNAME}.ctf)
set(CONTEXTPROP_EXAMPLE_MATLAB_SOURCE ${CMAKE_CURRENT_LIST_DIR}/matlab/${CONTEXTPROP_EXAMPLE_DEPLOYNAME}.m)
set(CONTEXTPROP_EXAMPLE_ROUTES ../../../examples/context_propagation/matlab/routes.json)  #somehow, only relative paths are allowed
matlab_get_version_from_matlab_run(${Matlab_MAIN_PROGRAM} Matlab_LIST_VERSION)
if(Matlab_LIST_VERSION VERSION_GREATER_EQUAL 23.2.0)
    # since MATLAB R2023b, route mapping can be specified at the archive level
    set(ARCHIVE_ROUTES ",ROUTES:${CONTEXTPROP_EXAMPLE_ROUTES}")
else()
    set(ARCHIVE_ROUTES "")
endif()

# A few libraries need to be moved to libmexclass.proxy package before calling mcc
add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${LIBMEXCLASS_PROXY_INSTALLED_DIR} 
	COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/${LIBMEXCLASS_PROXY_INSTALLED_DIR}
	COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${OPENTELEMETRY_MEX_GATEWAY_NAME}> $<TARGET_FILE:${OPENTELEMETRY_PROXY_LIBRARY_NAME}> 
	                                 $<TARGET_FILE:mexclass> ${OPENTELEMETRY_PROXY_RUNTIME_LIBRARIES} 
					 ${CMAKE_CURRENT_BINARY_DIR}/${LIBMEXCLASS_PROXY_INSTALLED_DIR} 
	DEPENDS ${OPENTELEMETRY_MEX_GATEWAY_NAME}) 

# Call mcc to create .ctf file for deployment with MATLAB Production Server
if(USE_BATCH_FOR_MCC)
    set(MCC_START matlab-batch \"mcc)
    set(MCC_END "\"")
else()
    set(MCC_START ${Matlab_MCC_COMPILER})
    set(MCC_END "")
endif()
add_custom_target(${CONTEXTPROP_EXAMPLE_MATLAB_TARGET} ALL 
	${MCC_START} -W CTF:${CONTEXTPROP_EXAMPLE_DEPLOYNAME}${ARCHIVE_ROUTES} -U ${CONTEXTPROP_EXAMPLE_MATLAB_SOURCE} 
	    -a ${CMAKE_SOURCE_DIR}/api/trace -a ${CMAKE_SOURCE_DIR}/api/context -a ${CMAKE_SOURCE_DIR}/api/common -a ${CMAKE_SOURCE_DIR}/sdk/trace 
	    -a ${CMAKE_SOURCE_DIR}/sdk/common -a ${CMAKE_SOURCE_DIR}/exporters/otlp -a ${${LIBMEXCLASS_FETCH_CONTENT_NAME}_SOURCE_DIR}/libmexclass/matlab 
	    -a ${CMAKE_CURRENT_BINARY_DIR}/${LIBMEXCLASS_PROXY_INSTALLED_DIR}${MCC_END}
	DEPENDS ${CONTEXTPROP_EXAMPLE_MATLAB_SOURCE} ${CMAKE_CURRENT_BINARY_DIR}/${LIBMEXCLASS_PROXY_INSTALLED_DIR})  
