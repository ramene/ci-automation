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

##Upload Spring Cloud Services Tile

om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" upload-product --product pcf-products/p-spring-cloud-services*.pivotal

#scs_product_version=$(pcf products | grep p-spring-cloud-services | awk '{print $3}')
scs_product_version=$(om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" available-products |grep p-spring-cloud-services | awk '{print $4}')

om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" stage-product --product-name p-spring-cloud-services --product-version ${scs_product_version}
