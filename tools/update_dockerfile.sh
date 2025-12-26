#!/usr/bin/bash

list_images(){
    grep -E '^[[:space:]]*FROM[[:space:]]+([^:[:space:]]+):.*$' $1 \
        | sed -E 's/^[[:space:]]*FROM[[:space:]]+([^:[:space:]]+):.*$/\1/'
}

tag_tools=$(dirname $0)/container_resolve_latest_tag.py

update_image_version(){
    Dockerfile=$1
    for image in $(list_images $Dockerfile); do
        echo "Detected image: $image in $Dockerfile."
        latest_version=$($tag_tools "${image}")
        echo "Last version is: ${latest_version}"
        sed -i -E "s|^(FROM[[:space:]]+${image}:)[^[:space:]]*|\1${latest_version}|I" "${Dockerfile}"
    done
}

# Go to work_dir
if [ -v 1 ]; then 
    cd "$1"
else
    cd "$(dirname "$0")"
fi
# Go to git root dir
if git rev-parse --show-toplevel &>/dev/null; then
    cd $(git rev-parse --show-toplevel)
fi

# Update Dockerfile with last version
find . -name 'Dockerfile' | while read -r file; do
    update_image_version "$file"
done
