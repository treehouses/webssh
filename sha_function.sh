#!/bin/bash

get_sha(){
    repo=$1
    docker pull $1 &>/dev/null
    #sha=$(docker image inspect $1 |jq .[0].RootFS.Layers |grep sha)
    sha=$(docker image inspect $1 | jq --raw-output '.[0].RootFS.Layers|.[]')   # [0] means first element of list,[]means all the elments of lists
    echo $sha
}

is_base (){
    local base_sha    # alpine
    local image_sha   # new image
    base_repo=$1
    image_repo=$2
    base_sha=$(get_sha $1)
    image_sha=$(get_sha $2)

    found="true"
    for i in $base_sha; do
        for j in $image_sha; do
            if [[ $i = $j ]]; then
                #echo "no change, same base image: $i"
                found="false"
                break
            fi
        done
    done
    echo "$found"
}

get_service_version(){
    local version
    repo=$1
    docker run -d $repo &>/dev/null
    container_id=$(docker ps | grep "$repo" | awk '{print$1;}')
    version=$(docker exec -it $container_id wssh --version)
    echo $version
    docker rm -f $container_id &>/dev/null
}

compare (){
    result=$(is_base $1 $2)
    version1=$(get_service_version $3)
    version2=$(get_service_version $4)
    if [ $result == "true" ] || [ "$version1" != "$version2" ]; #compare alpine and service versions
    then
        echo "true"
    else
        echo "false"
    fi
}

create_manifest (){
    local repo=$1 #treehouses/webssh
    local tag_latest=$2 #latest
    local tag_time=$3 #timetag
    local tag_arm=$4  #treehouses/webssh-tags:arm
    local tag_x86=$5
    local tag_arm64=$6
    docker manifest create $repo:$tag_latest $tag_arm $tag_x86 $tag_arm64
    docker manifest create $repo:$tag_time $tag_arm $tag_x86 $tag_arm64
    docker manifest annotate $repo:$tag_latest $tag_arm --arch arm
    docker manifest annotate $repo:$tag_latest $tag_x86 --arch amd64
    docker manifest annotate $repo:$tag_latest $tag_arm64 --arch arm64
    docker manifest annotate $repo:$tag_time $tag_arm --arch arm
    docker manifest annotate $repo:$tag_time $tag_x86 --arch amd64
    docker manifest annotate $repo:$tag_time $tag_arm64 --arch arm64
}
