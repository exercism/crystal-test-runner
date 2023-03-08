#!/usr/bin/env bash

set -euo pipefail

echo "Building json scaffold helper"
crystal build helpers/scaffold_json.cr --release -o bin/scaffold_json
echo "Building results json helper"
crystal build helpers/result_to_json.cr --release -o bin/result_to_json
echo "Building setup test file helper"
crystal build helpers/setup_test_file.cr --release -o bin/setup_test_file
