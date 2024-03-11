
# C++ target
set(CONTEXTPROP_EXAMPLE_TARGET contextprop_example_client)
add_executable(${CONTEXTPROP_EXAMPLE_TARGET} cpp/client.cc)
add_dependencies(${CONTEXTPROP_EXAMPLE_TARGET} ${OTEL_CPP_PROJECT_NAME})

target_include_directories(${CONTEXTPROP_EXAMPLE_TARGET} PRIVATE ${OTEL_CPP_PREFIX}/include)
target_link_libraries(${CONTEXTPROP_EXAMPLE_TARGET} PRIVATE ${OPENTELEMETRY_PROXY_LINK_LIBRARIES})
if(UNIX AND NOT APPLE AND NOT CYGWIN)
    target_link_options(${CONTEXTPROP_EXAMPLE_TARGET} PRIVATE ${OPENTELEMETRY_PROXY_LINK_OPTIONS})
elseif(APPLE)
    set_target_properties(${CONTEXTPROP_EXAMPLE_TARGET} PROPERTIES BUILD_RPATH "${CMAKE_INSTALL_PREFIX}/${LIBMEXCLASS_PROXY_INSTALLED_DIR}")
endif()
# use the same C++ standard as OpenTelemetry-cpp
target_compile_features(${CONTEXTPROP_EXAMPLE_TARGET} PRIVATE cxx_std_${OTEL_CPP_CXX_STANDARD})

# MATLAB target
find_package(Matlab REQUIRED COMPONENTS MCC_COMPILER MAIN_PROGRAM)

set(CONTEXTPROP_EXAMPLE_DEPLOYNAME mymagic)
set(CONTEXTPROP_EXAMPLE_MATLAB_SOURCE ${CMAKE_CURRENT_LIST_DIR}/matlab/${CONTEXTPROP_EXAMPLE_DEPLOYNAME}.m)
set(CONTEXTPROP_EXAMPLE_ROUTES ../../../examples/context_propagation/matlab/routes.json)  #somehow, only relative paths are allowed
matlab_get_version_from_matlab_run(${Matlab_MAIN_PROGRAM} Matlab_LIST_VERSION)
if(Matlab_LIST_VERSION VERSION_GREATER_EQUAL 23.2.0)
    # since MATLAB R2023b, route mapping can be specified at the archive level
    set(ARCHIVE_ROUTES ",ROUTES:${CONTEXTPROP_EXAMPLE_ROUTES}")
else()
    set(ARCHIVE_ROUTES "")
endif()
install(CODE "execute_process(COMMAND ${Matlab_MCC_COMPILER} -W CTF:${CONTEXTPROP_EXAMPLE_DEPLOYNAME}${ARCHIVE_ROUTES} -U ${CONTEXTPROP_EXAMPLE_MATLAB_SOURCE} -a ${CMAKE_INSTALL_PREFIX} -a ${CMAKE_INSTALL_PREFIX}/+libmexclass/+proxy WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})")
