#!/bin/bash
set -ex

# for rsamban/pcf-om (alpine image)
cp /om-alpine /usr/local/bin/om

# for ubuntu images
# apt-get update
# apt-get install -y wget
# wget https://github.com/pivotal-cf/om/releases/download/0.21.0/om-linux -O /usr/local/bin/om

chmod +x /usr/local/bin/om


# if first argument is passed, source it - used in jenkins builds
if [[ ! -z $1 ]]; then
  source $1
fi

if [[ -z $OPSMAN_HOST ]]; then echo "Please set OPSMAN_HOST"; exit 1; fi
if [[ -z $OPSMAN_USER ]]; then echo "Please set OPSMAN_USER"; exit 1; fi
if [[ -z $OPSMAN_PASSWORD ]]; then echo "Please set OPSMAN_PASSWORD"; exit 1; fi


echo "=============================================================================================="
echo " Uploading ERT tile to @ https://$OPSMAN_HOST ..."
echo "=============================================================================================="

##Upload ert Tile
om -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" upload-product --product pcf-products/cf*.pivotal

cf_product_version=$(om -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" available-products |grep cf | awk '{print $4}')

om -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" stage-product --product-name cf --product-version ${cf_product_version}
