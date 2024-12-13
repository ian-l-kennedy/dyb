#!/usr/bin/env bash

# Check for required arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_dyb>"
    exit 1
fi

dyb_file="$1"
url="https://raw.githubusercontent.com/ian-l-kennedy/milk-bash/main/src/milk.bash"
tl=curl

# Check if the required tool is available
if ! [ -x "$(command -v ${tl})" ]; then
    echo "${tl} is required, but ${tl} is not found on PATH."
    exit 1
fi

# Check if the magic comments are present in the file
if ! grep -q "# Copied contents of milk.bash" "${dyb_file}"; then
    echo "Error: '# Copied contents of milk.bash' comment not found in ${dyb_file}."
    exit 1
fi

if ! grep -q "# End of contents of milk.bash" "${dyb_file}"; then
    echo "Error: '# End of contents of milk.bash' comment not found in ${dyb_file}."
    exit 1
fi

# Fetch the remote content
remote_content=$(${tl} -kfsSL "${url}")

# Create a temporary file for the new dyb content
temp_file=$(mktemp)

# Read the dyb file and write the new content to the temporary file
inside_block=0
while IFS= read -r line; do
    if [[ "$line" == "# Copied contents of milk.bash" ]]; then
        echo "$line" >>"$temp_file"
        echo "$remote_content" >>"$temp_file"
        inside_block=1
    elif [[ "$line" == "# End of contents of milk.bash" ]]; then
        inside_block=0
        echo "$line" >>"$temp_file"
    elif [[ $inside_block -eq 0 ]]; then
        echo "$line" >>"$temp_file"
    fi
done <"$dyb_file"

# Replace the original file with the new content
mv "$temp_file" "$dyb_file"
chmod +x $dyb_file
echo "Successfully replaced the contents between the magic comments in ${dyb_file}."
