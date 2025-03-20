#!/bin/bash

TAG=${TAG:-dev}
PREFIX=${PREFIX:-registry-vpc.cn-beijing.aliyuncs.com/huweiwen-test/3fs}
PUSH=${PUSH:-false}

build_img() {
    buildctl build --frontend dockerfile.v0 \
        --local bin=super/build/3fs-prefix/src/3fs-build/bin \
        --local context=deploy/container \
        --local dockerfile=deploy/container \
        --opt context:bin=local:bin "$@"
}

build() {
    build_img --opt "target=$1" \
        --output "type=image,name=$PREFIX-$1:$TAG,push=$PUSH"
    build_img --opt "target=$1-debug" \
        --output "type=image,name=$PREFIX-$1:$TAG-debug,push=$PUSH"
}
build meta
build storage
build mgmtd
build admin-cli
build fuse

build_img --local data_placement=deploy/data_placement \
    --opt context:data_placement=local:data_placement \
    --opt "target=init" \
    --output "type=image,name=$PREFIX-init:$TAG,push=$PUSH"
