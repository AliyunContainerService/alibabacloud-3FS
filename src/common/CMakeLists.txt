include(${PROJECT_SOURCE_DIR}/cmake/GitVersion.cmake)
CheckGitSetup(${PROJECT_SOURCE_DIR})

set(FLATBUFFERS_FLATC_SCHEMA_EXTRA_ARGS --cpp-std=c++17)

target_add_lib(common memory-common version-info Folly::folly ibverbs scn::scn clickhouse-cpp-lib-static toml11 zstd::libzstd_static uring::uring)
add_dependencies(common MonitorCollectorService-fbs)
target_sources(common PRIVATE utils/Linenoise.c)

target_add_shared_from(hf3fs_common_shared common)
