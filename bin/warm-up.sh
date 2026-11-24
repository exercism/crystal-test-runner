#!/usr/bin/env bash

# Synopsis:
# Fill the Crystal compiler's cache at image build time.

# Crystal keeps an object file for each module of a compiled program in
# CRYSTAL_CACHE_DIR, in a folder named after the program's path. When a later
# compile produces identical code for a module, the compiler reuses its object
# file instead of running LLVM on it again. Most modules come from the standard
# library and the spec framework, and they are the same for every solution.
# Without this step, every run starts with an empty cache, and LLVM compiles
# all of them.

# The warm-up runs bin/run.sh on a small solution at /mnt/exercism-iteration,
# the path used in production, so its cache folder matches theirs.

set -euo pipefail

solution_dir=/mnt/exercism-iteration

mkdir -p "${solution_dir}"
cp -r warm-up/. "${solution_dir}/"
bin/run.sh warm-up "${solution_dir}/" "${solution_dir}/" > /dev/null
rm -rf "${solution_dir}" /tmp/output.json
