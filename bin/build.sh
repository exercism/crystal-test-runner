#!/usr/bin/env bash

set -euo pipefail

echo "Building test_runner"
crystal build src/test_runner.cr --release -o bin/test_runner
echo "Building setup test file helper"
crystal build helpers/setup_test_file.cr --release -o bin/setup_test_file
