#!/bin/bash
set -e

cp /om-alpine /usr/local/bin
chmod 755 /usr/local/bin/om-alpine

echo "=============================================================================================="
echo "Deploying Ops Manager version $OPSMAN_VERSION ..."
echo "=============================================================================================="

#Configure Opsman
om-alpine --target https://$OPSMAN_HOST -k \
     configure-authentication \
       --username "$OPSMAN_USER" \
       --password "$OPSMAN_PASSWORD" \
       --decryption-passphrase "$OPSMAN_PASSWORD"
