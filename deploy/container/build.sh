#!/bin/bash
build() {
    buildctl build --frontend dockerfile.v0 \
        --local bin=build/bin \
        --local context=deploy/container \
        --local dockerfile=deploy/container \
        --opt context:bin=local:bin \
        --opt "target=$1" \
        --output "type=image,name=registry-vpc.cn-beijing.aliyuncs.com/huweiwen-test/3fs-$1:latest,push=true"
    buildctl build --frontend dockerfile.v0 \
        --local bin=build/bin \
        --local context=deploy/container \
        --local dockerfile=deploy/container \
        --opt context:bin=local:bin \
        --opt "target=$1-debug" \
        --output "type=image,name=registry-vpc.cn-beijing.aliyuncs.com/huweiwen-test/3fs-$1:latest-debug,push=true"
}
build meta
build storage
build mgmtd
build admin-cli
build fuse
