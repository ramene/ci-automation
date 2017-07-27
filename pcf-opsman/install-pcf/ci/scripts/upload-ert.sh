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

# pcf import $(ls pcf-products/cf*)

##Upload ert Tile

om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" upload-product --product pcf-products/cf*.pivotal

#cf_product_version=$(pcf products |grep cf | awk '{print $3}')
cf_product_version=$(om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" available-products |grep cf | awk '{print $4}')

om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" stage-product --product-name cf --product-version ${cf_product_version}

##Get Uploaded Tile --product-version

# opsman_host=$OPSMAN_HOST
# uaac target https://${opsman_host}/uaa --skip-ssl-validation > /dev/null 2>&1
# uaac token owner get opsman ${OPSMAN_USER} -s "" -p ${OPSMAN_PASSWORD} > /dev/null 2>&1
# export opsman_bearer_token=$(uaac context | grep access_token | awk -F ":" '{print$2}' | tr -d ' ')

# cf_product_version=$(curl -s -k -X GET -H "Content-Type: application/json" -H "Authorization: Bearer ${opsman_bearer_token}" "https://${opsman_host}/api/v0/available_products" | jq ' .[] | select ( .name == "cf") | .product_version ' | tr -d '"')

##Move 'available product to 'staged'

