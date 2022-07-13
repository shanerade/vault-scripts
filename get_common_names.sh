#!/usr/bin/env bash

CERT_PATH=${1:-cert}

printf "Using '$CERT_PATH' for mount path. Press ENTER to continue or CTRL+C to cancel. "
read waitwhat

rm all_cert_names.txt all_cert_cns.txt 2>/dev/null
vault list -format=json auth/${CERT_PATH}/certs | jq -r .[] > all_cert_names.txt

for i in $(cat all_cert_names.txt); do
    vault read -format=json auth/${CERT_PATH}/certs/$i | \
    jq -cr .data.certificate | \
    openssl x509 -in- -noout -text -subject | \
    grep Subject | \
    sed -n -e 's/^.*CN = //p' >> all_cert_cns.txt
done
