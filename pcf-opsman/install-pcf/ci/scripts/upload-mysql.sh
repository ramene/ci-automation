#!/bin/bash
set -e

cp /om-alpine /usr/local/bin

cp /pcf-metadata metadata

sed -i -e "s#{{opsman_url}}#https://${OPSMAN_HOST}#g" metadata
sed -i -e "s/{{opsman_username}}/${OPSMAN_USER}/g" metadata
sed -i -e "s/{{opsman_password}}/${OPSMAN_PASSWORD}/g" metadata

echo "=============================================================================================="
echo " Uploading MySql tile to @ https://$OPSMAN_HOST ..."
echo "=============================================================================================="

#pcf import $(ls pcf-products/p-mysql*)

##Upload mysql Tile

om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" upload-product --product pcf-products/p-mysql*.pivotal

#mysql_product_version=$(pcf products |grep p-mysql | awk '{print $3}')
mysql_product_version=$(om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" available-products | grep p-mysql | awk '{print $4}')

om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" stage-product --product-name p-mysql --product-version ${mysql_product_version}
