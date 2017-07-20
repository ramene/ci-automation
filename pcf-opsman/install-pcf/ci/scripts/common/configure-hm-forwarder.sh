#!/bin/bash
set -e

# for rsamban/pcf-om (alpine image)
cp /om-alpine /usr/local/bin/om

# for ubuntu images
# apt-get update
# apt-get install -y wget jq
# wget https://github.com/pivotal-cf/om/releases/download/0.21.0/om-linux -O /usr/local/bin/om

chmod +x /usr/local/bin/om

CWD=$(pwd)


if [[ -z $OPSMAN_HOST ]]; then echo "Please set OPSMAN_HOST"; exit 1; fi
if [[ -z $OPSMAN_USER ]]; then echo "Please set OPSMAN_USER"; exit 1; fi
if [[ -z $OPSMAN_PASSWORD ]]; then echo "Please set OPSMAN_PASSWORD"; exit 1; fi
if [[ -z $HM_FORWORDER_TEMPLATE_DIR ]]; then echo "Please set HM_FORWORDER_TEMPLATE_DIR"; exit 1; fi
if [[ -z $HM_FORWORDER_NETWORK_CONFIG_JSON ]]; then echo "Please set HM_FORWORDER_NETWORK_CONFIG_JSON"; exit 1; fi
if [[ -z $HM_FORWORDER_JOBS_CONFIG_JSON ]]; then echo "Please set HM_FORWORDER_JOBS_CONFIG_JSON"; exit 1; fi
if [[ -z $HM_FORWORDER_NETWORK ]]; then echo "Please set HM_FORWORDER_NETWORK"; exit 1; fi

INTERNET_CONNECTED=${INTERNET_CONNECTED:-false}

#configure network and az

NETWORK_AND_AZ="$(source $HM_FORWORDER_TEMPLATE_DIR/$HM_FORWORDER_NETWORK_CONFIG_JSON)"
echo "===========================================Network and AZs Config==================================================="
echo "NETWORK_AND_AZ = $NETWORK_AND_AZ"
echo "=============================================================================================="
JOB_CONFIG="$(source $HM_FORWORDER_TEMPLATE_DIR/$HM_FORWORDER_JOBS_CONFIG_JSON)"
echo "===========================================Jobs Config==================================================="
echo "JOB_CONFIG = $JOB_CONFIG"
echo "=============================================================================================="

# configure network and azs
echo "Executing om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n bosh-hm-forwarder -pn \"${NETWORK_AND_AZ}\" ..."
om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n bosh-hm-forwarder -pn "${NETWORK_AND_AZ}" 


# configure jobs
echo "Executing om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n bosh-hm-forwarder -pr \"${JOB_CONFIG}\" ..."
om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n bosh-hm-forwarder -pr "${JOB_CONFIG}"
