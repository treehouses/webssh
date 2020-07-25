#!/usr/bin/env bash

if [[ $# -le 1 ]]; then
    echo "missing parameters."
    exit 1
fi

dir=$(dirname $0)
sha=$($dir/manifest-alpine-sha.sh $@)       # $1 <source>/alpine:latest  amd64|arm|arm64
echo $sha
base_image="treehouses/alpine@$sha"
echo $base_image
arch=$2   # arm arm64 amd64

if [ -n "$sha" ]; then
        tag=treehouses/webssh-tags:$arch
        echo $tag                           #treehouses/webssh-tags:arm
        sed "s|{{base_image}}|$base_image|g" Dockerfile.template > Dockerfile.$arch
        docker build -t $tag -f Dockerfile.$arch .
        docker push $tag
fi