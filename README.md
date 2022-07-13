### Various scripts for working with [vault]().

* `get_common_names.sh` - Pulls all x509 certs from PKI auth mount and prints out the CN (common name) of each to a file.
* `clean_cert_identities.sh` - Loops through identities for a particular PKI auth mount and checks the name (CN in this case) against a list of currently enabled certificates on the aformentioned mount path. If it's not found in the list, and it's the only alias tied to the identity, the identity can be deleted. This is likely to be used in conjuction with `get_common_names.sh`
* `revoke_all_tokens.sh` - Loops through all tokens for a particular auth mount path and revokes each.
