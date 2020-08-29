#!/bin/bash

arch=$1  # arm arm64 amd64
tag_arch=treehouses/webssh-tags:$arch
tag_time=$(date +%Y%m%d%H%M)
tag_arch_time=treehouses/webssh-tags:$arch-$tag_time
echo $tag_arch_time

docker tag $tag_arch $tag_arch_time
docker push $tag_arch_time
docker tag $tag_arch_time $tag_arch
docker push $tag_arch