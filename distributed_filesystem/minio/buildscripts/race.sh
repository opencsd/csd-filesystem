#!/usr/bin/env bash

set -e

## TODO remove `dsync` from race detector once this is merged and released https://go-review.googlesource.com/c/go/+/333529/
for d in $(go list ./... | grep -v dsync); do
    CGO_ENABLED=1 go test -v -race --timeout 100m "$d"
done
