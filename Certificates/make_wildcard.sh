#!/bin/bash

# Makes a wildcard certificate and requisite root CA if it doesn't exist

[ -z $1 ] && echo "Must include wildcard domain name as parameter, ex: *.mydomain.com" && exit 1

WILDCARD_DOMAIN=$1
DOMAIN="${WILDCARD_DOMAIN:2}"

# Create cnf config file for the CA
#echo -e "[ req_distinguished_name ]\ncountryName = US\nstateOrProvinceName = Indiana\nlocalityName = Noblesville\norganizationName = FOSSbox\norganizationalunitName = N/A\ncommonName = ${WILDCARD_DOMAIN}\nemailAddress = toddbt73@gmail.com\n" > ${DOMAIN}-CA.cnf

# Create cnf config file for the domain
echo -e "[req]\ndefault_md = sha256\nprompt = no\nreq_extensions = req_ext\ndistinguished_name = req_distinguished_name\n[req_distinguished_name]\ncommonName = ${WILDCARD_DOMAIN}\ncountryName = US\nstateOrProvinceName = Indiana\nlocalityName = Noblesville\norganizationName = FOSSbox\n[req_ext]\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=critical,serverAuth,clientAuth\nsubjectAltName = @alt_names\n[alt_names]\nDNS.1=${DOMAIN}\nDNS.2=${WILDCARD_DOMAIN}" > ${DOMAIN}.cnf


if [ ! -f CA.crt ]; then
    # 1) Make CA key with password
    openssl genrsa -des3 -out CA.key 4096
    # 2) Make CA cert using key providing password
    openssl req -new -x509 -days 3650 -key CA.key -out CA.crt
fi
# 3) Make wildcard's cert key
openssl genrsa -out ${DOMAIN}.key 2048
# 4) Make cnf config file for wildcard cert

# 5) Create CSR using config file
openssl req -new -nodes -key ${DOMAIN}.key -config ${DOMAIN}.cnf -out ${DOMAIN}.csr
# 6) Verify subject alternative names from cnf file exist
openssl req -noout -text -in ${DOMAIN}.csr
# 7) Submit the csr for signing with the CA
openssl x509 -req -in ${DOMAIN}.csr -CA CA.crt -CAkey CA.key -CAcreateserial -out ${DOMAIN}.crt -days 3650 -sha256 -extfile ${DOMAIN}.cnf -extensions req_ext
