#!/usr/bin/env bats

function prep_tests() {
    docker ps -q | xargs -r docker stop
    cd "${BATS_TEST_DIRNAME}"
    dyb_file="${BATS_TEST_DIRNAME}/../src/dyb"
}

function clean_tests() {
    cd "${BATS_TEST_DIRNAME}"
    git clean -fdX .
}

# Test to verify that the local block of content in the dyb file matches the remote file content from a URL
@test "test_copy_of_milk_bash" {
    # Call the pre-test function
    prep_tests

    url="https://raw.githubusercontent.com/ian-l-kennedy/milk-bash/main/src/milk.bash"
    tl=curl

    # Check if the required tool (curl) is available
    if ! [ -x "$(command -v ${tl})" ]; then
        echo "${tl} is required, but ${tl} is not found on PATH."
        exit 1
    fi

    # Fetch the remote content
    remote_content=$(${tl} -kfsSL "${url}")

    # Extract the block of content between the magic comments in the dyb file
    local_block=$(sed -n '/# Copied contents of milk.bash/,/# End of contents of milk.bash/ p' "${dyb_file}" | sed '1d;$d')

    # Compare the local block with the remote content
    if [ "${local_block}" != "${remote_content}" ]; then
        echo "Error: Local block does not match the remote file content."
        exit 1
    else
        echo "Success: Local block matches the remote file content."
    fi

    # Call the post-test function
    clean_tests
}

# Test to verify the dyb command with an empty YAML file
@test "test_blank_dyb" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}

    # Create an empty YAML file
    touch ${yml}

    # Run the dyb command with the empty YAML file
    dyb echo "hello world"
    [ "$?" -eq 0 ]

    # Call the post-test function
    clean_tests
}

# Test to verify that the dyb command fails when given an invalid make target
@test "test_failure_inside_docker_exec" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}

    # Create an empty YAML file
    touch ${yml}

    # Run the dyb command with an invalid make target and capture the exit code
    set +e
    dyb supercagifragilisticexpialidoshious
    local exit_code_dyb=$?
    set -e

    # Verify that the dyb command fails
    [ "$exit_code_dyb" -ne 0 ]

    # Call the post-test function
    clean_tests
}

# Test to verify that the Docker image is created with the default tag from the YAML file
@test "test_dyb_docker_image_tag_default" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}

    # Create a YAML file with the default Docker image tag
    touch ${yml}

    # Remove any existing Docker image with the name dyb_docker_image
    docker rmi -f dyb_docker_image 2>/dev/null || true

    # Run the dyb command
    dyb echo "hello world"
    [ "$?" -eq 0 ]

    # Verify that the Docker image was created
    docker images | grep -q "dyb_docker_image"
    [ "$?" -eq 0 ]

    # Cleanup: Remove the created Docker image
    docker rmi -f dyb_docker_image 2>/dev/null || true

    # Call the post-test function
    clean_tests
}

# Test to verify that the Docker image is created with the specified tag from the YAML file
@test "test_dyb_docker_image_tag" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}

    # Create a YAML file with the specified Docker image tag
    touch ${yml}
    echo 'docker_image_tag: sample_image' >>${yml}

    # Remove any existing Docker image with the name sample_image
    docker rmi -f sample_image 2>/dev/null || true

    # Run the dyb command
    dyb echo "hello world"
    [ "$?" -eq 0 ]

    # Verify that the Docker image was created
    docker images | grep -q "sample_image"
    [ "$?" -eq 0 ]

    # Cleanup: Remove the created Docker image
    docker rmi -f sample_image 2>/dev/null || true

    # Call the post-test function
    clean_tests
}

@test "test_field_docker_build_params_append" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}
    touch ${yml}
    echo 'docker_build_params_append:' >>${yml}
    echo '  - --quiet' >>${yml}
    echo '  - --platform=linux/amd64' >>${yml}
    echo 'docker_run_params_append: --platform=linux/amd64 -v=/tmp:/tmp:rw' >>${yml}
    dyb echo "hello world"
    [ "$?" -eq 0 ]
    rm ${yml}
}

@test "test_field_docker_build_params_append_with_bash_commands" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}
    touch ${yml}
    echo 'docker_build_params_append: $(echo "--quiet") $(echo '--platform=linux/amd64')' >>${yml}
    echo 'docker_run_params_append: --platform=linux/amd64 -v=/tmp:/tmp:rw' >>${yml}
    dyb echo "hello world"
    [ "$?" -eq 0 ]
    [ "$(docker container ls -a | wc -l)" -eq 1 ]
}

@test "test_field_as_array_docker_build_params_append" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}
    touch ${yml}
    echo 'docker_build_params_append: ["--quiet", "--platform=linux/amd64"]' >>${yml}
    echo 'docker_run_params_append: --platform=linux/amd64 -v=/tmp:/tmp:rw' >>${yml}
    dyb echo "hello world"
    [ "$?" -eq 0 ]
    rm ${yml}
}

@test "test_field_docker_run_params_append" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}
    touch ${yml}
    echo 'docker_build_params_append:' >>${yml}
    echo '  - --quiet' >>${yml}
    echo '  - --platform=linux/amd64' >>${yml}
    echo 'docker_run_params_append: --platform=linux/amd64 -v=/tmp:/tmp:rw' >>${yml}
    dyb echo "hello world"
    [ "$?" -eq 0 ]
    rm ${yml}
}

@test "test_field_as_array_docker_run_params_append" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}
    touch ${yml}
    echo 'docker_build_params_append: ["--quiet", "--platform=linux/amd64"]' >>${yml}
    echo 'docker_run_params_append: ["--platform=linux/amd64","-v=/tmp:/tmp:rw"]' >>${yml}
    dyb echo "hello world"
    [ "$?" -eq 0 ]
    rm ${yml}
}

@test "test_field_docker_run_params_append_sans_amd64" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}
    touch ${yml}
    echo 'docker_run_params_append: -v=/tmp:/tmp:rw' >>${yml}
    dyb echo "hello world"
    [ "$?" -eq 0 ]
    rm ${yml}
}

@test "test_field_as_array_docker_run_params_append_sans_amd64" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}
    touch ${yml}
    echo 'docker_run_params_append: ["-v=/tmp:/tmp:rw"]' >>${yml}
    dyb echo "hello world"
    [ "$?" -eq 0 ]
    rm ${yml}
}

@test "test_dyb_with_valid_bash_commands" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}

    # Create a valid YAML file with bash commands
    touch ${yml}
    echo 'docker_image_tag: valid_image' >>${yml}
    echo 'docker_build_params_append: ["--quiet"]' >>${yml}
    echo 'docker_run_params_append: ["-v=/tmp:/tmp:rw"]' >>${yml}
    echo 'bash_command: echo "Hello, World!"' >>${yml}

    # Run the dyb command
    dyb echo "hello world"
    [ "$?" -eq 0 ]

    # Verify that the Docker image was created
    docker images | grep -q "valid_image"
    [ "$?" -eq 0 ]

    # Cleanup: Remove the created Docker image
    docker rmi -f valid_image 2>/dev/null || true

    # Call the post-test function
    clean_tests
}

@test "test_field_docker_build_params_append_with_bash_commands_list" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}

    # Create a valid YAML file with bash commands
    touch ${yml}
    echo 'docker_build_params_append: docker-image' >>${yml}
    echo 'docker_build_params_append:' >>${yml}
    echo '  - $(echo "--quiet")' >>${yml}
    echo '  - $(echo '--platform=linux/amd64')' >>${yml}
    echo 'docker_run_params_append:' >>${yml}
    echo '  - $(echo "--quiet")' >>${yml}
    echo '  - $(echo "-v=/tmp:/tmp:rw")' >>${yml}

    # Run the dyb command
    dyb echo "hello world"
    [ "$?" -eq 0 ]

    # Verify that the Docker image was created
    docker images | grep -q "valid_image"
    [ "$?" -eq 0 ]

    # Cleanup: Remove the created Docker image
    docker rmi -f valid_image 2>/dev/null || true

    # Call the post-test function
    clean_tests
}

@test "test_dyb_with_missing_yaml" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}

    # Ensure the YAML file is missing
    [ ! -f ${yml} ]

    # Run the dyb command and capture the exit code
    set +e
    dyb echo "hello world"
    local exit_code_dyb=$?
    set -e

    # Verify that the dyb command fails
    [ "$exit_code_dyb" -ne 0 ]
}

@test "test_empty_docker_run_params_append_in_dyb" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}

    # Create a YAML file with an empty docker_run_params_append field
    touch ${yml}
    echo 'docker_run_params_append:' >>${yml}
    echo '  - ""' >>${yml}

    # Run the dyb command
    dyb echo "hello world"
    [ "$?" -eq 0 ]

    # Call the post-test function
    clean_tests
}

@test "test_dyb_with_relative_paths_left" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}

    # Create a YAML file with relative paths
    touch ${yml}
    echo 'relative_path_to_dockerfile: ../Dockerfile' >>${yml}

    # Create a dummy Dockerfile
    cp Dockerfile ../Dockerfile

    # Run the dyb command
    dyb echo "hello world"
    [ "$?" -eq 0 ]

    # Remove the YAML file and Dockerfile after the test
    rm -f ${yml} ../Dockerfile
}

@test "test_dyb_with_relative_paths_right" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}
    mkdir -p dummy/path

    # Create a YAML file with relative paths
    touch ${yml}
    echo 'relative_path_to_dockerfile: dummy/path/Dockerfile' >>${yml}

    # Create a dummy Dockerfile
    cp Dockerfile dummy/path/Dockerfile

    # Run the dyb command
    dyb echo "hello world"
    [ "$?" -eq 0 ]

    # Remove the YAML file and Dockerfile after the test
    rm -f ${yml} dummy/path/Dockerfile
}

@test "test_dyb_with_invalid_dockerfile_path" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}

    # Create a YAML file with an invalid Dockerfile path
    touch ${yml}
    echo 'relative_path_to_dockerfile: invalid_path/Dockerfile' >>${yml}

    # Run the dyb command and capture the exit code
    set +e
    dyb echo "hello world"
    local exit_code_dyb=$?
    set -e

    # Verify that the dyb command fails
    [ "$exit_code_dyb" -ne 0 ]

    # Call the post-test function
    clean_tests
}

@test "test_dyb_with_valid_docker_run_params" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}

    # Create a YAML file with valid docker run parameters
    touch ${yml}
    echo 'docker_image_tag: valid_run_image' >>${yml}
    echo 'docker_run_params_append: ["-v=/tmp:/tmp:rw"]' >>${yml}

    # Run the dyb command
    dyb echo "hello world"
    [ "$?" -eq 0 ]

    # Verify that the Docker image was created
    docker images | grep -q "valid_run_image"
    [ "$?" -eq 0 ]

    # Cleanup: Remove the created Docker image
    docker rmi -f valid_run_image 2>/dev/null || true

    # Call the post-test function
    clean_tests
}

@test "test_dyb_with_workspace_flag" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}

    # Create a YAML file
    touch ${yml}

    # Run the dyb command with the --dev_workspace_container flag
    dyb --dev_workspace_container
    [ "$?" -eq 0 ]

    # Verify that the Docker container is running
    docker ps | grep -q "dyb_workspace_dcontainer_"
    [ "$?" -eq 0 ]

    # Cleanup: Stop and remove the Docker container
    docker stop $(docker ps -q --filter "name=dyb_workspace_dcontainer_") 2>/dev/null || true
    docker rm $(docker ps -a -q --filter "name=dyb_workspace_dcontainer_") 2>/dev/null || true

    # Call the post-test function
    clean_tests
}

@test "test_dyb_does_not_run_commands_with_workspace_flag" {
    # Call the pre-test function
    prep_tests

    export PATH=$(dirname $(pwd))/src:$PATH
    yml=dyb.yml
    rm -f ${yml}

    # Create a YAML file
    touch ${yml}

    # Run the dyb command with the --dev_workspace_container flag and a make target
    dyb --dev_workspace_container hello_world
    [ "$?" -eq 0 ]

    # Verify that the Docker container is running
    docker ps | grep -q "dyb_workspace_dcontainer_"
    [ "$?" -eq 0 ]

    # Verify that the make command was not run inside the container
    # Here we assume the command creates a file `hello_world_done` which should not exist
    [ ! -f hello_world_done ]

    # Cleanup: Stop and remove the Docker container
    docker stop $(docker ps -q --filter "name=dyb_workspace_dcontainer_") 2>/dev/null || true
    docker rm $(docker ps -a -q --filter "name=dyb_workspace_dcontainer_") 2>/dev/null || true

    # Call the post-test function
    clean_tests
}
