set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
# Conflict with abseil_dll.dll used by Simulink. Use static library to avoid conflict.
if(${PORT} MATCHES "abseil")
    set(VCPKG_LIBRARY_LINKAGE static)
else()
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()

