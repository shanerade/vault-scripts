#!/bin/bash

CERT_PATH=${1:-cert}
ALL_CNS=${2:-all_cert_cns.txt}
WORKDIR=${3:-entities}

printf "Using '$CERT_PATH' for mount path and pulling common names from file '$ALL_CNS'. Press ENTER to continue or CTRL+C to cancel."
read waitwhat

mkdir ${WORKDIR} >/dev/null 2>&1

# Retrieve listing of all identity entities.
vault list --format json identity/entity/id | jq -r .[] > ${WORKDIR}/all_entities.txt

# Loop through each entity.
for id in $(cat ${WORKDIR}/all_entities.txt); do
    # Save the entity info to lessen calls to vault
    vault read -format=json identity/entity/id/${id} > ${WORKDIR}/${id}.json

    # Pull aliases and alias count from entity.
    aliases=$(cat ${WORKDIR}/${id}.json | jq -cr '.data.aliases[]')
    alias_num=$(echo $aliases | wc -l)

    # For each entity alias, test to see if it matches
    # the mount path we're interested in.
    # If it does, check it's name in the list of common names
    # currently configured in vault (valid). If it's not found that means
    # the cert has since been deleted and we can safely remove this alias.
    for alias in ${aliases}; do
        mountpath=$(echo $alias | jq -r '.mount_path')
        alias_id=$(echo $alias | jq -r '.id')
        if [[ "${mountpath}" =~ ^auth/${CERT_PATH}/.* ]]; then
            cn=$(echo $alias | jq -r '.name')
            if ! grep ${cn} ${ALL_CNS} >/dev/null 2>&1; then
                echo [*] ${cn} not found, deleting entity-alias ${alias_id}
                vault delete identity/entity-alias/id/${alias_id}
            fi
        fi
    done

    # Check if there any aliases left (for another auth type or cert mount path) if not, we can delete this identity.
    # If there *are* other aliases, we probably don't want to delete it right now.
    alias_num=$(vault read -format=json identity/entity/id/${id} | jq -c -r '.data.aliases[]' | wc -l)
    if [[ "${alias_num}" -eq 0 ]]; then
        echo [*] ${id} contains no more aliases, deleting...
        vault delete identity/entity/id/${id}
    fi
done

