if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CARGO_CMD cargo rustc --lib)
    set(TARGET_DIR "debug")
else ()
    set(CARGO_CMD cargo rustc --lib --release)
    set(TARGET_DIR "release")
endif ()

macro(add_crate NAME)
    set(LIBRARY "${PROJECT_SOURCE_DIR}/target/${TARGET_DIR}/lib${NAME}.a")
    set(SOURCES
        "${PROJECT_SOURCE_DIR}/target/cxxbridge/${NAME}/src/cxx.rs.h"
        "${PROJECT_SOURCE_DIR}/target/cxxbridge/${NAME}/src/cxx.rs.cc"
    )

    add_custom_target(crate_${NAME}
        COMMAND ${CMAKE_COMMAND} -E env ROCKSDB_LIB_DIR=$<TARGET_FILE_DIR:RocksDB::rocksdb> ROCKSDB_STATIC=1 ZSTD_SYS_USE_PKG_CONFIG=1 ${CARGO_CMD}
        BYPRODUCTS ${SOURCES} ${LIBRARY}
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${NAME}"
        USES_TERMINAL
    )

    add_library(${NAME} STATIC ${SOURCES})
    target_link_libraries(${NAME} pthread dl ${LIBRARY})
    target_include_directories(${NAME} PUBLIC "${PROJECT_SOURCE_DIR}/target/cxxbridge")
    target_compile_options(${NAME} PUBLIC -Wno-dollar-in-identifier-extension)
endmacro()
