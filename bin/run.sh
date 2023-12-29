#!/usr/bin/env bash

# Synopsis:
# Run the test runner on a solution.

# Arguments:
# $1: exercise slug
# $2: absolute path to solution folder
# $3: absolute path to output directory

# Output:
# Writes the test results to a results.json file in the passed-in output directory.
# The test results are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Example:
# ./bin/run.sh two-fer /absolute/path/to/two-fer/solution/folder/ /absolute/path/to/output/directory/

# If any required arguments is missing, print the usage and exit
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "usage: ./bin/run.sh exercise-slug /absolute/path/to/two-fer/solution/folder/ /absolute/path/to/output/directory/"
    exit 1
fi

slug="$1"
snake_slug=${slug//-/_}
input_dir="${2%/}"
output_dir="${3%/}"
spec_file="${input_dir}/$(jq -r '.files.test[0]' ${input_dir}/.meta/config.json)"
modified_spec_file="${input_dir}/spec/modified_test_spec.cr"
capture_file="${output_dir}/capture"
scaffold_file="${output_dir}/scaffold.json"
junit_file="${output_dir}/output.xml"
results_file="${output_dir}/results.json"

# Create the output directory if it doesn't exist
mkdir -p "${output_dir}"

echo "${slug}: testing..."

./bin/setup_test_file "${spec_file}" "${modified_spec_file}"

# Run the tests for the provided implementation file and redirect stdout and
# stderr to capture it
crystal spec "${modified_spec_file}" --junit_output="${output_dir}" --no-color &> "${capture_file}"

./bin/test_runner "${spec_file}" "${capture_file}" "${junit_file}" "${results_file}"

echo "${slug}: done"
