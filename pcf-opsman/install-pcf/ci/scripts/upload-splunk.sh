#!/bin/bash
set -e

cp /om-alpine /usr/local/bin

cp /pcf-metadata metadata

sed -i -e "s#{{opsman_url}}#https://${OPSMAN_HOST}#g" metadata
sed -i -e "s/{{opsman_username}}/${OPSMAN_USER}/g" metadata
sed -i -e "s/{{opsman_password}}/${OPSMAN_PASSWORD}/g" metadata

echo "=============================================================================================="
echo " Uploading ERT tile to @ https://$OPSMAN_HOST ..."
echo "=============================================================================================="

#pcf import $(ls pcf-splunk-tile-get/splunk-ecs*)

##Upload ert Tile

om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" upload-product --product pcf-products/splunk-ecs*.pivotal

splunk_product_version=$(pcf products |grep splunk-ecs | awk '{print $3}')

om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" stage-product --product-name splunk-ecs --product-version ${splunk_product_version}
