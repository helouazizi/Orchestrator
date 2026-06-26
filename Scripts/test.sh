
    vars=""

    while read -r var; do

        envs=$(grep "^${var}=" ../.env | tr -d '\n')
        vars+=" $envs"

    done < <(grep -oP '(?<=\$)\w+' "../Manifests/inventory_database.yml")
    vars=$(echo "$vars" | xargs)
    echo vars: $vars

    export $vars
