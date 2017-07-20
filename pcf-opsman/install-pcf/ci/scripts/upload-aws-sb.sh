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

pcf import $(ls pcf-products/aws-services*)

##Upload ert Tile

#om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" upload-product --product pcf-products/aws-services*.pivotal

aws_sb_product_version=$(pcf products |grep aws-services | awk '{print $3}')

om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" stage-product --product-name aws-services --product-version ${aws_sb_product_version}
