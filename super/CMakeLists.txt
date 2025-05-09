cmake_minimum_required(VERSION 3.12)
project(3FS_SUPER NONE)

include(ExternalProject)

set(INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/usr)

ExternalProject_Add(zstd
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/zstd
    SOURCE_SUBDIR build/cmake
    INSTALL_DIR ${INSTALL_DIR}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> -DZSTD_BUILD_STATIC=ON -DZSTD_BUILD_SHARED=OFF -DZSTD_BUILD_PROGRAMS=OFF
)

ExternalProject_Add(liburing
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/liburing
    BUILD_IN_SOURCE ON
    INSTALL_DIR ${INSTALL_DIR}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure --prefix=<INSTALL_DIR>
    BUILD_COMMAND make ENABLE_SHARED=0 -j8
    INSTALL_COMMAND make install ENABLE_SHARED=0
)

ExternalProject_Add(rocksdb
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/rocksdb
    INSTALL_DIR ${INSTALL_DIR}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> -DCMAKE_PREFIX_PATH=<INSTALL_DIR>
        -DWITH_LZ4=ON -DWITH_ZSTD=ON -DWITH_SNAPPY=ON -DWITH_LIBURING=ON -DUSE_RTTI=ON
        -DWITH_TESTS=OFF -DWITH_BENCHMARK_TOOLS=OFF -DWITH_TOOLS=OFF -DROCKSDB_BUILD_SHARED=OFF
        -DGFLAGS_USE_TARGET_NAMESPACE=ON
    USES_TERMINAL_BUILD ON
)
ExternalProject_Add_StepDependencies(rocksdb configure zstd liburing)

ExternalProject_Add(leveldb
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/leveldb
    INSTALL_DIR ${INSTALL_DIR}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
        -DLEVELDB_BUILD_TESTS=OFF -DLEVELDB_BUILD_BENCHMARKS=OFF
)

ExternalProject_Add(arrow
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/arrow
    SOURCE_SUBDIR "cpp"
    INSTALL_DIR ${INSTALL_DIR}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> -DCMAKE_PREFIX_PATH=<INSTALL_DIR>
        -DARROW_DEPENDENCY_SOURCE=SYSTEM -Dxsimd_SOURCE=BUNDLED
        -DThrift_SOURCE=BUNDLED  # Ubuntu version acquires Qt, which is large
        -DARROW_BUILD_STATIC=ON
        -DARROW_JEMALLOC=ON
        -DARROW_SIMD_LEVEL=DEFAULT
        -DARROW_BUILD_EXAMPLES=OFF
        -DARROW_PARQUET=ON -DARROW_CSV=ON
        -DARROW_WITH_ZSTD=ON -DARROW_ZSTD_USE_SHARED=OFF -DARROW_WITH_LZ4=ON -DARROW_WITH_ZLIB=ON
    USES_TERMINAL_BUILD ON
)
ExternalProject_Add_StepDependencies(arrow configure zstd)

ExternalProject_Add(fmt
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/fmt
    INSTALL_DIR ${INSTALL_DIR}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> -DFMT_MASTER_PROJECT=OFF
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
)

ExternalProject_Add(folly
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/folly
    INSTALL_DIR ${INSTALL_DIR}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> -DCMAKE_PREFIX_PATH=<INSTALL_DIR>
        -DFOLLY_NO_EXCEPTION_TRACER=ON
        -DGFLAGS_USE_TARGET_NAMESPACE=ON
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    USES_TERMINAL_BUILD ON
)
ExternalProject_Add_StepDependencies(folly configure fmt zstd liburing)

ExternalProject_Add(libfuse
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/libfuse
    INSTALL_DIR ${INSTALL_DIR}
    CONFIGURE_COMMAND meson setup --prefix <INSTALL_DIR> --buildtype release --default-library static -D examples=false -D tests=false -D utils=false <SOURCE_DIR>
    BUILD_COMMAND ninja
    INSTALL_COMMAND ninja install
)

ExternalProject_Add(mimalloc
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/mimalloc
    INSTALL_DIR ${INSTALL_DIR}
    CMAKE_ARGS -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR> -DMI_OVERRIDE=OFF
)

ExternalProject_add(jemalloc
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../third_party/jemalloc
    INSTALL_DIR ${INSTALL_DIR}
    BUILD_IN_SOURCE ON
    CONFIGURE_COMMAND ./autogen.sh --prefix=<INSTALL_DIR> --disable-cxx --enable-prof --disable-initial-exec-tls --disable-shared
)

add_library(3fs_deps INTERFACE)
add_dependencies(3fs_deps zstd liburing rocksdb leveldb arrow libfuse fmt folly mimalloc jemalloc)

ExternalProject_add(3fs
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..
    INSTALL_DIR ${INSTALL_DIR}
    CMAKE_ARGS -DCMAKE_PREFIX_PATH=<INSTALL_DIR>
    BUILD_COMMAND ${CMAKE_COMMAND} --build . -t mgmtd_main meta_main storage_main admin_cli hf3fs_fuse_main
    USES_TERMINAL_BUILD ON
    BUILD_ALWAYS ON
    INSTALL_COMMAND ""
)
ExternalProject_Add_StepDependencies(3fs configure 3fs_deps)
