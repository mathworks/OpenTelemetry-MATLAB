set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
# Conflict with abseil_dll.dll used by Simulink. Use static library to avoid conflict.
if(${PORT} MATCHES "abseil")
    set(VCPKG_LIBRARY_LINKAGE static)
else()
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()
# Define a preprocessor macro _DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR to work around an invalid MEX file issue
# See https://github.com/mathworks/OpenTelemetry-Matlab/issues/130
set(VCPKG_CXX_FLAGS "/D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR")
set(VCPKG_C_FLAGS "/D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR")
