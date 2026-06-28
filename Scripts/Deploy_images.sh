#!/bin/bash

set -e

#upload environment variables
source ../.env

parent=$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")
echo "Parent directory: $parent"
services=( "api-gateway-app" "billing-app" "inventory-app" "billing-database" "inventory-database" "rabbit-queue" )

for d in "${services[@]}"; do
    echo "Deploying $d"
    docker build -t $d $parent/"Dockerfiles"/$d
    image_name=$docker_username/$d":v1.0"
    docker tag $d $image_name
    echo $docker_access_key | docker login -u $docker_username --password-stdin
    docker push $image_name
done