#!/bin/bash

get_manifest_sha (){
    local repo=$1     # <source>/alpine:latest
    local arch=$2     # arm
    docker pull -q $repo &>/dev/null
    docker manifest inspect $repo > "$arch".txt
    sha=""
    local i=0
    while [ "$sha" == "" ] && read -r line
    do
        archecture=$(jq .manifests[$i].platform.architecture "$arch".txt |sed -e 's/^"//' -e 's/"$//')
        if [ "$archecture" = "$arch" ];then
            sha=$(jq .manifests[$i].digest "$arch".txt  |sed -e 's/^"//' -e 's/"$//')
            echo ${sha}
        fi
        i=$i+1
    done < "$arch".txt
}

get_sha(){
    docker pull $1 &>/dev/null
    sha=$(docker image inspect $1 | jq --raw-output '.[0].RootFS.Layers|.[]')   # [0] means first element of list,[]means all the elments of lists
    echo $sha
}

is_base (){
    local base_sha    # alpine
    local image_sha   # new image
    local base_repo=$1
    local image_repo=$2

    base_sha=$(get_sha $base_repo)
    image_sha=$(get_sha $image_repo)

    for i in $base_sha; do
        local found="false"
        for j in $image_sha; do
            if [[ $i = $j ]]; then
                found="true"
                break
            fi
        done
        if [ $found == "false" ]; then
            echo "false"
            return 0
        fi
    done
    echo "true"
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
    result_arm=$(is_base $1 $2)
    result_arm64=$(is_base $3 $4)
    result_amd64=$(is_base $5 $6)
    version1=$(get_service_version $7) #current on the docker hub (latest)
    version2=$(get_service_version $8) #tag-amd64 newly built
    if [ $result_arm == "false" ] || [ $result_amd64 == "false" ] || [ $result_arm64 == "false" ] || [ "$version1" != "$version2" ];     #compare alpine and service versions
    then
        echo "true"
    else
        echo "false"
    fi
}

create_manifest (){
    local repo=$1           #treehouses/webssh
    local tag_latest=$2     #latest
    local tag_time=$3       #timetag
    local tag_arm=$4        #treehouses/webssh-tags:arm
    local tag_arm64=$5
    local tag_x86=$6
    docker manifest create   $repo:$tag_latest $tag_arm $tag_x86 $tag_arm64
    docker manifest create   $repo:$tag_time   $tag_arm $tag_x86 $tag_arm64

    docker manifest annotate $repo:$tag_latest $tag_arm   --arch arm
    docker manifest annotate $repo:$tag_time   $tag_arm   --arch arm
    docker manifest annotate $repo:$tag_latest $tag_x86   --arch amd64
    docker manifest annotate $repo:$tag_time   $tag_x86   --arch amd64
    docker manifest annotate $repo:$tag_latest $tag_arm64 --arch arm64
    docker manifest annotate $repo:$tag_time   $tag_arm64 --arch arm64
}
