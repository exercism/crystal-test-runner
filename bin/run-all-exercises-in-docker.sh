#!/usr/bin/env sh
set -e

# Synopsis:
# Run the test runner on all the practice exercises using the test runner Docker image.
# The test runner Docker image is built automatically.

# Arguments:
# $1: absolute path to exercises folder
# $2: absolute path to output directory

# Output:
# Writes the test results to a results.json file in the passed-in output directory.
# The test results are formatted according to the specifications at https://github.com/exercism/docs/blob/main/building/tooling/test-runners/interface.md

# Example:
# ./bin/run-all-exercises-in-docker.sh absolute/path/exercises /absolute/path/to/output/directory/

# If any required arguments is missing, print the usage and exit
if [ -z "$1" ] || [ -z "$2" ]; then
   echo "usage: ./bin/run-in-docker.sh absolute/path/exercises /absolute/path/to/output/directory/"
    exit 1
fi

input_dir="${1%/}"
output_dir="${2%/}"

# Create the output directory if it doesn't exist
mkdir -p "${output_dir}"

# Build the Docker image
docker build --rm -t exercism/test-runner .

# Run the Docker image using the settings mimicking the production environment
tmpdir="$(mktemp -d)"
touch ${output_dir}/result.json
jq -n '{}' > ${output_dir}/result.json

for test_dir in ${input_dir}/*; do
    spec_file=$(jq -r '.files.solution[0]' ${test_dir}/.meta/config.json)
    echo "${test_dir}"
    cp -a -r ${test_dir}/. ${tmpdir}
    cp -a -r ${tmpdir}/.meta/src/example.cr ${tmpdir}/${spec_file}
    output_tmpdir="$(mktemp -d)"
    docker run \
        --rm \
        --read-only \
        --network none \
        --mount type=bind,src="${tmpdir}",dst=/solution \
        --mount type=bind,src="${output_tmpdir}",dst=/output \
        --mount type=volume,dst=/tmp \
        exercism/test-runner "$(basename ${test_dir})" /solution /output
    if [ -s ${output_tmpdir}/results.json ]; then
        jq '.' ${output_tmpdir}/results.json | sponge ${output_tmpdir}/results.json
        jq --arg key "$(basename ${test_dir})" --argfile new_data "${output_tmpdir}/results.json" '.[$key] = $new_data' ${output_dir}/result.json | sponge ${output_dir}/result.json
    else 
        jq --arg key "$(basename ${test_dir})" '.[$key] = "fail"' ${output_dir}/result.json | sponge ${output_dir}/result.json
    fi
    if jq -e '.[] | select(. == "fail")' ${output_tmpdir}/results.json || ! [ -s ${output_tmpdir}/results.json ]; then
        if ! [ -s ${output_dir}/fail.json ]; then
        touch ${output_dir}/fail.json
        jq -n '{}' > ${output_dir}/fail.json
        jq '. += {"exercises": []}' ${output_dir}/fail.json | sponge ${output_dir}/fail.json
        fi
        jq --arg key "$(basename ${test_dir})" '.exercises += [$key]' ${output_dir}/fail.json | sponge ${output_dir}/fail.json
    fi
done
