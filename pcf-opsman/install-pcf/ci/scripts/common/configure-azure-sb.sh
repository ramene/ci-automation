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
if [[ -z $AZURE_SB_TEMPLATE_DIR ]]; then echo "Please set AZURE_SB_TEMPLATE_DIR"; exit 1; fi
if [[ -z $AZURE_SB_NETWORK_CONFIG_JSON ]]; then echo "Please set AZURE_SB_NETWORK_CONFIG_JSON"; exit 1; fi
if [[ -z $AZURE_SB_PROPERTIES_JSON ]]; then echo "Please set AZURE_SB_PROPERTIES_JSON"; exit 1; fi
if [[ -z $AZURE_SB_JOBS_CONFIG_JSON ]]; then echo "Please set AZURE_SB_JOBS_CONFIG_JSON"; exit 1; fi
if [[ -z $AZURE_SB_NETWORK ]]; then echo "Please set AZURE_SB_NETWORK"; exit 1; fi
if [[ -z $AZURE_SB_ENVIRONMENT ]]; then echo "Please set AZURE_SB_ENVIRONMENT"; exit 1; fi
if [[ -z $AZURE_SB_DATABASE_ENCRYPTION_KEY ]]; then echo "Please set AZURE_SB_DATABASE_ENCRYPTION_KEY"; exit 1; fi

INTERNET_CONNECTED=${INTERNET_CONNECTED:-false}

#configure network and az

NETWORK_AND_AZ="$(source $AZURE_SB_TEMPLATE_DIR/$AZURE_SB_NETWORK_CONFIG_JSON)"
echo "===========================================Network and AZs Config==================================================="
echo "NETWORK_AND_AZ = $NETWORK_AND_AZ"
echo "=============================================================================================="
JOB_CONFIG="$(source $AZURE_SB_TEMPLATE_DIR/$AZURE_SB_JOBS_CONFIG_JSON)"
echo "===========================================Jobs Config==================================================="
echo "JOB_CONFIG = $JOB_CONFIG"
echo "=============================================================================================="

PROPERTIES="$(source $AZURE_SB_TEMPLATE_DIR/$AZURE_SB_PROPERTIES_JSON)"
echo "===========================================Ert Properties==================================================="
echo "PROPERTIES = $PROPERTIES"
echo "=============================================================================================="

# configure network and azs
echo "Executing om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n azure-service-broker -pn \"${NETWORK_AND_AZ}\" ..."
om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n azure-service-broker -pn "${NETWORK_AND_AZ}" 


# configure properties

echo "Executing om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n azure-service-broker -p \"${PROPERTIES}\" ..."
om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n azure-service-broker -p "${PROPERTIES}"

# configure jobs
echo "Executing om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n azure-service-broker -pr \"${JOB_CONFIG}\" ..."
om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n azure-service-broker -pr "${JOB_CONFIG}"
