#!/bin/bash

# You need to run `podman unshare` before running this script

COMPONENT_FILE=acs-scan-components.txt
image_id=""
prev_image=""
container_path=""

> components.out

while IFS= read -r line;
do
  image_repo=$(echo $line | cut -d@ -f1,2)
  image_component=$(echo $line | cut -d@ -f3)

  if [[ $prev_image != $image_repo ]]
  then
    echo
    echo "Pulling ${image_repo} ..."
    image_id=$(podman pull -q ${image_repo})
    container_id=$(podman create ${image_id})
    container_path=$(podman mount ${container_id})
  fi

  if [[ ! -z $container_path ]]
  then
    echo "Looking for $image_component in ${container_path} ..."
    component=$(find $container_path -name $image_component)
    if [[ -z $component ]]
    then
       echo "${image_repo}: ${image_component} not found ..." >> components.out
    fi
  fi

  prev_image=$image_repo
done < ${COMPONENT_FILE}
