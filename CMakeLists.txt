cmake_minimum_required(VERSION 3.12)
project(3FS VERSION 0.1.5 LANGUAGES C CXX)

set(CMAKE_CONFIGURATION_TYPES "RelWithDebInfo;Debug;Release;MinSizeRel" CACHE STRING "" FORCE)
if (NOT CMAKE_BUILD_TYPE OR CMAKE_BUILD_TYPE STREQUAL "None")
    set (CMAKE_BUILD_TYPE "RelWithDebInfo")
    message (STATUS "CMAKE_BUILD_TYPE is not set, set to default = ${CMAKE_BUILD_TYPE}")
endif ()
message (STATUS "CMAKE_BUILD_TYPE: ${CMAKE_BUILD_TYPE}")

string (TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE_UC)

if(CMAKE_BUILD_TYPE_UC STREQUAL "DEBUG" )
    option(ENABLE_ASSERTIONS "Enable assertions" ON)
else()
    option(ENABLE_ASSERTIONS "Enable assertions" OFF)
endif()
message (STATUS "ENABLE_ASSERTIONS: ${ENABLE_ASSERTIONS}")

if(ENABLE_ASSERTIONS)
    add_definitions(-D_DEBUG)
    # On non-Debug builds cmake automatically defines NDEBUG, so we explicitly undefine it:
    if(NOT CMAKE_BUILD_TYPE_UC STREQUAL "DEBUG")
        # NOTE: use `add_compile_options` rather than `add_definitions` since
        # `add_definitions` does not support generator expressions.
        add_compile_options($<$<OR:$<COMPILE_LANGUAGE:C>,$<COMPILE_LANGUAGE:CXX>>:-UNDEBUG>)
    endif()
endif()

option(OVERRIDE_CXX_NEW_DELETE "Override C++ new/delete operator" OFF)
option(SAVE_ALLOCATE_SIZE "Use more memory to save allocate size" OFF)

option(ENABLE_FUSE_APPLICATION "" ON)

if (DEFINED SANITIZER AND SANITIZER)
    set(OVERRIDE_CXX_NEW_DELETE OFF)
endif()
message (STATUS "OVERRIDE_CXX_NEW_DELETE: ${OVERRIDE_CXX_NEW_DELETE}")

if (OVERRIDE_CXX_NEW_DELETE)
    add_definitions(-DOVERRIDE_CXX_NEW_DELETE)
    if (SAVE_ALLOCATE_SIZE)
        add_definitions(-DSAVE_ALLOCATE_SIZE)
    endif()
endif()
message (STATUS "SAVE_ALLOCATE_SIZE: ${SAVE_ALLOCATE_SIZE}")

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED OFF)
set(CMAKE_C_EXTENSIONS ON)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fcoroutines-ts")
    set(CMAKE_CXX_LINK_FLAGS "${CMAKE_CXX_LINK_FLAGS} -latomic")
    add_link_options(-fuse-ld=lld)
    # Do not build with libc++ (LLVM's implementation of the C++ standard library) in fdb
    set(USE_LIBCXX OFF)
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fcoroutines")
endif()

# Remove project root from the __FILE__ macro variable
add_compile_options(-fmacro-prefix-map=${CMAKE_SOURCE_DIR}=.)

if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
    add_compile_options(-msse4.2 -mavx2)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    # ARM architecture detected:
    # Clang on ARM uses built-in runtime library (compiler-rt) to provide symbols like '__muloti4'.
    # Without explicitly specifying '-rtlib=compiler-rt', linking may fail due to missing '__muloti4'.
    # '-unwindlib=libgcc' ensures proper exception unwinding compatibility.
    add_compile_options(-march=armv8-a)
    message(STATUS "ARM architecture detected, linking with compiler-rt and libgcc.")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -rtlib=compiler-rt -unwindlib=libgcc")
endif()
include(cmake/Sanitizers.cmake)
include(FindPkgConfig)

find_package(fmt REQUIRED)
find_package(zstd REQUIRED)
find_package(folly REQUIRED)
find_package(RocksDB REQUIRED)
find_package(leveldb REQUIRED)
find_package(Arrow REQUIRED)
find_package(Parquet REQUIRED)
find_package(uring REQUIRED)  # RocksDB provides this
find_package(mimalloc REQUIRED)
pkg_check_modules(jemalloc REQUIRED IMPORTED_TARGET jemalloc)
pkg_check_modules(fuse3 REQUIRED IMPORTED_TARGET fuse3)

add_subdirectory("third_party/googletest" EXCLUDE_FROM_ALL)

set(SCN_TESTS OFF)
set(SCN_EXAMPLES OFF)
set(SCN_BENCHMARKS OFF)
set(SCN_DOCS OFF)
set(SCN_INSTALL OFF)
set(SCN_PEDANTIC OFF)
add_subdirectory("third_party/scnlib" EXCLUDE_FROM_ALL)

add_subdirectory("third_party/pybind11" EXCLUDE_FROM_ALL)

add_subdirectory("third_party/toml11" EXCLUDE_FROM_ALL)

add_subdirectory("third_party/clickhouse-cpp" EXCLUDE_FROM_ALL)
TARGET_INCLUDE_DIRECTORIES(clickhouse-cpp-lib
    PUBLIC ${PROJECT_SOURCE_DIR}/third_party/clickhouse-cpp
)
TARGET_INCLUDE_DIRECTORIES(clickhouse-cpp-lib-static
    PUBLIC ${PROJECT_SOURCE_DIR}/third_party/clickhouse-cpp
)
TARGET_INCLUDE_DIRECTORIES (absl-lib
    PUBLIC ${PROJECT_SOURCE_DIR}/third_party/clickhouse-cpp/contrib
)

set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Werror -Wpedantic")

set (CMAKE_CXX_FLAGS                     "${CMAKE_CXX_FLAGS} ${COMPILER_FLAGS}")
set (CMAKE_CXX_FLAGS_RELWITHDEBINFO      "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} -O3 ${DEBUG_INFO_FLAGS} ${CMAKE_CXX_FLAGS_ADD}")
set (CMAKE_CXX_FLAGS_DEBUG               "${CMAKE_CXX_FLAGS_DEBUG} -O0 ${DEBUG_INFO_FLAGS} -fno-inline ${CMAKE_CXX_FLAGS_ADD}")

set (CMAKE_C_FLAGS                       "${CMAKE_C_FLAGS} ${COMPILER_FLAGS} ${CMAKE_C_FLAGS_ADD}")
set (CMAKE_C_FLAGS_RELWITHDEBINFO        "${CMAKE_C_FLAGS_RELWITHDEBINFO} -O3 ${DEBUG_INFO_FLAGS} ${CMAKE_C_FLAGS_ADD}")
set (CMAKE_C_FLAGS_DEBUG                 "${CMAKE_C_FLAGS_DEBUG} -O0 ${DEBUG_INFO_FLAGS} -fno-inline ${CMAKE_C_FLAGS_ADD}")

set (CMAKE_ASM_FLAGS                     "${CMAKE_ASM_FLAGS} ${COMPILER_FLAGS} ${CMAKE_ASM_FLAGS_ADD}")
set (CMAKE_ASM_FLAGS_RELWITHDEBINFO      "${CMAKE_ASM_FLAGS_RELWITHDEBINFO} -O3 ${DEBUG_INFO_FLAGS} ${CMAKE_ASM_FLAGS_ADD}")
set (CMAKE_ASM_FLAGS_DEBUG               "${CMAKE_ASM_FLAGS_DEBUG} -O0 ${DEBUG_INFO_FLAGS} -fno-inline ${CMAKE_ASM_FLAGS_ADD}")

set(Boost_USE_STATIC_LIBS ON)
set(FDB_VERSION 7.1.5-ibe)

find_package(Threads REQUIRED)
find_package(Boost CONFIG REQUIRED COMPONENTS filesystem system program_options)
find_library(LIBUV_LIBRARY NAMES libuv1)
enable_testing()

include(cmake/CodeCoverage.cmake)
include(cmake/CLangFormat.cmake)
include(cmake/CLangTidy.cmake)
include(cmake/Target.cmake)
include(cmake/DumpConfig.cmake)
include(cmake/AddCrate.cmake)
configure_file(cmake/CTestCustom.cmake ${CMAKE_BINARY_DIR} @ONLY)

add_subdirectory(src)
add_subdirectory(tests)
add_subdirectory(benchmarks)
