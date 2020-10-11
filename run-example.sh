#!/bin/sh

set -Eeuo pipefail

swift build

./.build/debug/replexample
