#!/bin/bash

set -e

cd "$(dirname "$0")"

if git -C ../third_party/folly apply --reverse --check ../../patches/folly.patch &>/dev/null; then
    echo "folly patch already applied. skipping."
else
    git -C ../third_party/folly apply ../../patches/folly.patch
fi
