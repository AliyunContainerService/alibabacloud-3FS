target_add_lib(hf3fs_fuse common core-app meta-client storage-client PkgConfig::fuse3 client-lib-common)
target_add_bin(hf3fs_fuse_main hf3fs_fuse.cpp hf3fs_fuse)

if (ENABLE_FUSE_APPLICATION)
target_compile_definitions(hf3fs_fuse PUBLIC -DENABLE_FUSE_APPLICATION)
endif()
