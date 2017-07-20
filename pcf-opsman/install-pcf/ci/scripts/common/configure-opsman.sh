#!/bin/bash

set -e

# for rsamban/pcf-om (alpine image)
cp /om-alpine /usr/local/bin/om

#for ubuntu images
# apt-get update
# apt-get install -y wget jq
# wget https://github.com/pivotal-cf/om/releases/download/0.21.0/om-linux -O /usr/local/bin/om

chmod +x /usr/local/bin/om

# if first argument is passed, source it - used in jenkins builds
if [[ ! -z $1 ]]; then
  source $1
fi

if [[ -z $OPSMAN_HOST ]]; then echo "Please set OPSMAN_HOST"; exit 1; fi
if [[ -z $OPSMAN_USER ]]; then echo "Please set OPSMAN_USER"; exit 1; fi
if [[ -z $OPSMAN_PASSWORD ]]; then echo "Please set OPSMAN_PASSWORD"; exit 1; fi
if [[ -z $DECRYPT_PASSWORD ]]; then echo "Please set DECRYPT_PASSWORD"; exit 1; fi

echo "=============================================================================================="
echo "Configuring Ops Manager for Internal Authentication..."
echo "=============================================================================================="

#Configure Opsman
om -t https://$OPSMAN_HOST -k configure-authentication -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" -dp "$DECRYPT_PASSWORD"

echo "=============================================================================================="
echo "Configuring Ops Manager for Internal Authentication. Done."
echo "=============================================================================================="
