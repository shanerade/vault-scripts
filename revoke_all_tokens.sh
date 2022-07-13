#!/bin/bash

# Pass the name of the mount point in parameter or 
# through the $AUTH_MOUNT_POINT environment variable. Defaults to ldap
DEFAULT_MOUNT_NAME=${1-ldap}
: ${AUTH_MOUNT_POINT_NAME:=$DEFAULT_MOUNT_NAME}

for accessor in $(vault list --format json auth/token/accessors | jq -r .[])
do
    path=$(vault write --field path auth/token/lookup-accessor accessor=${accessor})
    if [[ "$path" =~ ^auth/$AUTH_MOUNT_POINT_NAME.* ]]
    then
        echo Revoking $path ...
        vault write auth/token/revoke-accessor accessor=${accessor}
    fi
done
