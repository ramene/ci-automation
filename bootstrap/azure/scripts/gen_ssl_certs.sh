#!/bin/bash

set -ex

if [[ -z $1 ]]; then
  echo "usage: gen_ssl_certs.sh CONCOURSE_HOST TLS_KEY_FILE TLS_CERT_FILE"
  exit 1
fi
if [[ -z $2 ]]; then
  echo "usage: gen_ssl_certs.sh CONCOURSE_HOST TLS_KEY_FILE TLS_CERT_FILE"
  exit 1
fi
if [[ -z $3 ]]; then
  echo "usage: gen_ssl_certs.sh CONCOURSE_HOST TLS_KEY_FILE TLS_CERT_FILE"
  exit 1
fi

CONCOURSE_HOST=$1
CONCOURSE_PIP=$2
TLS_KEY_FILE=$3
TLS_CERT_FILE=$4

SSL_FILE=sslconf-${CONCOURSE_HOST}.conf

#Generate SSL Config with SANs
if [ ! -f $SSL_FILE ]; then
 cat > $SSL_FILE <<EOM
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[req_distinguished_name]
#countryName = Country Name (2 letter code)
#countryName_default = US
#stateOrProvinceName = State or Province Name (full name)
#stateOrProvinceName_default = TX
#localityName = Locality Name (eg, city)
#localityName_default = Frisco
#organizationalUnitName     = Organizational Unit Name (eg, section)
#organizationalUnitName_default   = Pivotal Labs
#commonName = Pivotal
#commonName_max = 64
[ v3_req ]
# Extensions to add to a certificate request
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = ${CONCOURSE_PIP}
EOM
fi

openssl genrsa -out ${TLS_KEY_FILE} 2048
openssl req -new -out ${CONCOURSE_HOST}.csr -subj "/C=US/ST=Colorado/L=GreenwoodVillage/O=Ecsteam/OU=dev/CN=${CONCOURSE_HOST}" -key ${TLS_KEY_FILE} -config ${SSL_FILE}
openssl req -text -noout -in ${CONCOURSE_HOST}.csr
openssl x509 -req -days 3650 -in ${CONCOURSE_HOST}.csr -signkey ${TLS_KEY_FILE} -out ${TLS_CERT_FILE} -extensions v3_req -extfile ${SSL_FILE}
openssl x509 -in ${TLS_CERT_FILE} -text -noout
