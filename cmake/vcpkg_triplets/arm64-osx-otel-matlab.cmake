set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
if(${PORT} MATCHES "(curl|zlib)")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
else()
    set(VCPKG_LIBRARY_LINKAGE static)
endif()
# disable the script to fix rpath for curl, which makes an undesirable change to
# the install name from @rpath/libcurl.4.dylib to @rpath/libcurl.4.8.0.dylib
if(${PORT} MATCHES "curl")
    set(VCPKG_FIXUP_MACHO_RPATH OFF)
endif()


set(VCPKG_CMAKE_SYSTEM_NAME Darwin)
set(VCPKG_OSX_ARCHITECTURES arm64)
