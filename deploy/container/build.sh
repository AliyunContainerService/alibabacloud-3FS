#!/bin/bash

TAG=${1:latest}

build() {
    buildctl build --frontend dockerfile.v0 \
        --local bin=super/build/3fs-prefix/src/3fs-build/bin \
        --local context=deploy/container \
        --local dockerfile=deploy/container \
        --opt context:bin=local:bin \
        --opt "target=$1" \
        --output "type=image,name=registry-vpc.cn-beijing.aliyuncs.com/huweiwen-test/3fs-$1:$TAG,push=true"
    buildctl build --frontend dockerfile.v0 \
        --local bin=super/build/3fs-prefix/src/3fs-build/bin \
        --local context=deploy/container \
        --local dockerfile=deploy/container \
        --opt context:bin=local:bin \
        --opt "target=$1-debug" \
        --output "type=image,name=registry-vpc.cn-beijing.aliyuncs.com/huweiwen-test/3fs-$1:$TAG-debug,push=true"
}
build meta
build storage
build mgmtd
build admin-cli
# build fuse  # FIXME: libfuse.so
