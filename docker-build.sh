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

if [[ $# -le 1 ]]; then
    echo "missing parameters."
    exit 1
fi

repo=$1

for i in ${@:2}
do
    sha=$(get_manifest_sha $repo $i)        #$1 treehouses/alpine:latest  amd64|arm|arm64
    echo $sha
    base_image="treehouses/alpine@$sha"
    echo $base_image
    arch=$i   # arm arm64 amd64

    if [ -n "$sha" ]; then
            tag_arch=treehouses/webssh-tags:$arch
            echo $tag_arch                       #treehouses/webssh-tags:arm
            sed "s|{{base_image}}|$base_image|g" Dockerfile.template > Dockerfile.$arch
            docker build -t $tag_arch -f Dockerfile.$arch .
    fi
done
