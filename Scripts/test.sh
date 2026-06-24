#!/bin/bash

set -e
# search for all yaml files to extract variables from

files=$(find ../Manifests -name "*.yml" -o -name "*.yaml")

for file in $files; do
    # search for all variables in the yaml file and check if they are defined in the .env file
    while read -r var; do
        envs=$(grep "^${var}=" ../.env)
        export $envs | xargs && envsubst < $file
        break
    done < <(grep -oP '(?<=\$)\w+' "$file")
done


