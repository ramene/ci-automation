#!/bin/bash
set -e

cp /om-alpine /usr/local/bin
chmod 755 /usr/local/bin/om-alpine

echo "=============================================================================================="
echo " Uploading tiles and/or stemcells to @ https://$OPSMAN_HOST ..."
echo "=============================================================================================="

#delete unused products
echo "Deleting unused prodicts ..."
om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" delete-unused-products

#upload all the stemcells
stemcellCount=$(ls pcf-products/*.tgz 2> /dev/null | wc -l)
if [[ $stemcellCount != 0 ]]; then
    for file in pcf-products/*.tgz; do
        echo "============ Uploading stemcell $file Begin ============"
        om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" upload-stemcell --stemcell $file
        echo "============ Uploading stemcell $file End ============"
    done
fi

#upload all the products
productCount=$(ls pcf-products/*.pivotal 2> /dev/null | wc -l)
if [[ $productCount != 0 ]]; then
    for file in pcf-products/*.pivotal; do
        echo "============ Uploading product $file Begin ============"
        om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" upload-product --product $file
        echo "============ Uploading product $file End ============"
    done
fi
