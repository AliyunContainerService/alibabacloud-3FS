#!/bin/bash

set -e

BUILD_ID=$(file "/build/bin/$1" | grep -oP 'BuildID\[xxHash\]=\K[0-9a-f]+')
DEBUG_PATH="/out/.build-id/${BUILD_ID:0:2}/${BUILD_ID:2}.debug"
mkdir -p "$(dirname "$DEBUG_PATH")"
objcopy --only-keep-debug --compress-debug-sections "/build/bin/$1" "$DEBUG_PATH"
objcopy --strip-debug --remove-section=.comment --remove-section=.note "/build/bin/$1" "/out/$1"
chmod -x "$DEBUG_PATH"
