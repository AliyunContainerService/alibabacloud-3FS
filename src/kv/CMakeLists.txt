add_library(leveldb_logger STATIC LevelDBLogger.cpp)
target_link_libraries(leveldb_logger common leveldb::leveldb)
target_compile_options(leveldb_logger PRIVATE "-fno-rtti")

target_add_lib(kv common leveldb::leveldb leveldb_logger RocksDB::rocksdb)
