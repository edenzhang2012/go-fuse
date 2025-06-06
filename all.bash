#!/bin/bash
set -eux

# Kernel version is relevant to debugging CI failures
uname -a

# Everything must compile on Linux
go build ./...

# Not everything compiles on MacOS (try GOOS=darwin go build ./...).
# But our key packages should.
GOOS=darwin go build ./fs/... ./example/loopback/...
GOOS=freebsd go build ./fs/... ./example/loopback/...

# Run the tests. Why the flags:
# -timeout 5m ... Get a backtrace on a hung test before the CI system kills us
# -p 1 .......... Run tests serially, which also means we get live output
#                 instead of per-package buffering.
# -count 1 ...... Disable result caching, so we can see flakey tests
GO_TEST="go test -timeout 5m -p 1 -count 1"
# Run all tests as current user
$GO_TEST ./...
# The following tests need to run as root
sudo env PATH=$PATH $GO_TEST -run 'Test(DirectMount|Forget|Passthrough|IDMappedMount)' ./fs ./fuse

make -C benchmark
go test ./benchmark -test.bench '.*' -test.cpu 1,2
