#!/bin/bash
set -e

cp /om-alpine /usr/local/bin

cp /pcf-metadata metadata

sed -i -e "s#{{opsman_url}}#https://${OPSMAN_HOST}#g" metadata
sed -i -e "s/{{opsman_username}}/${OPSMAN_USER}/g" metadata
sed -i -e "s/{{opsman_password}}/${OPSMAN_PASSWORD}/g" metadata

echo "=============================================================================================="
echo " Uploading SCS tile to @ https://$OPSMAN_HOST ..."
echo "=============================================================================================="

#pcf import $(ls pcf-products/p-spring-cloud-services*)

##Upload Stemcells

stemcells=$(ls pcf-products/*.tgz)
for stemcell in $stemcells; do
    om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" upload-stemcell --stemcell $stemcell
done
