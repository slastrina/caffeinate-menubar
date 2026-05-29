#!/usr/bin/env bash
# Wrapper around `swift test` that adds the framework search/runtime paths
# Command Line Tools needs to locate the swift-testing framework.
# Plain `swift test` works on machines with full Xcode installed.
set -euo pipefail

FRAMEWORKS_DIR=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
INTEROP_DIR=/Library/Developer/CommandLineTools/Library/Developer/usr/lib

exec swift test \
    -Xswiftc -F -Xswiftc "$FRAMEWORKS_DIR" \
    -Xlinker -F -Xlinker "$FRAMEWORKS_DIR" \
    -Xlinker -rpath -Xlinker "$FRAMEWORKS_DIR" \
    -Xlinker -rpath -Xlinker "$INTEROP_DIR" \
    "$@"
