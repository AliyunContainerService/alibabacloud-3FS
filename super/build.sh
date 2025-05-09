export CC=clang-14
export CXX=clang++-14
export CFLAGS="-msse4.2 -mavx2"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="-fuse-ld=lld"
export CMAKE_BUILD_TYPE=RelWithDebInfo
cmake -S . -B build -GNinja
cmake --build build
