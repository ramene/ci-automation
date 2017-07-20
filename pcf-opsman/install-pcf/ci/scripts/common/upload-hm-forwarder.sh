#!/bin/bash
set -ex

# if first argument is passed, source it - used in jenkins builds
if [[ ! -z $1 ]]; then
  source $1
fi

if [[ -z $OPSMAN_HOST ]]; then echo "Please set OPSMAN_HOST"; exit 1; fi
if [[ -z $OPSMAN_USER ]]; then echo "Please set OPSMAN_USER"; exit 1; fi
if [[ -z $OPSMAN_PASSWORD ]]; then echo "Please set OPSMAN_PASSWORD"; exit 1; fi
if [[ -z $HM_FORWARDER_DOWNLOAD_LINK ]]; then echo "Please set HM_FORWARDER_DOWNLOAD_LINK"; exit 1; fi

HM_FORWARDER_FILE_NAME=hm_forwarder.pivotal

# for rsamban/pcf-om (alpine image)
cp /om-alpine /usr/local/bin/om

# for ubuntu images
# apt-get update
# apt-get install -y wget
# wget https://github.com/pivotal-cf/om/releases/download/0.21.0/om-linux -O /usr/local/bin/om

# get hm forwarder

wget $HM_FORWARDER_DOWNLOAD_LINK -O $HM_FORWARDER_FILE_NAME

chmod +x /usr/local/bin/om

echo "=============================================================================================="
echo " Uploading ERT tile to @ https://$OPSMAN_HOST ..."
echo "=============================================================================================="


##Upload stemcell for hm forwarder tile
om -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" upload-stemcell --stemcell azure-stemcell/*.tgz

##Upload hm forwarder Tile
om -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" upload-product --product $HM_FORWARDER_FILE_NAME

hm_forwarder_product_version=$(om -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" available-products | grep bosh-hm-forwarder | awk '{print $4}')

om -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" stage-product --product-name bosh-hm-forwarder --product-version ${hm_forwarder_product_version}
