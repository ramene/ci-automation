#!/bin/bash

set -ex

START_TIME=`date`
echo "Begin $START_TIME"

# if first argument is passed, source it - used in jenkins builds
if [[ ! -z $1 ]]; then
  source $1
fi

# 
if [[ -z $AZURE_SP_CI_USER ]]; then echo "Please set AZURE_SP_CI_USER"; exit 1; fi
if [[ -z $AZURE_SP_CI_PASSWORD ]]; then echo "Please set AZURE_SP_CI_PASSWORD"; exit 1; fi
if [[ -z $TENANT_ID ]]; then echo "Please set TENANT_ID"; exit 1; fi
if [[ -z $SUBSCRIPTION_ID ]]; then echo "Please set SUBSCRIPTION_ID"; exit 1; fi
if [[ -z $PCF_RESOURCE_GROUP ]]; then echo "Please set PCF_RESOURCE_GROUP"; exit 1; fi
if [[ -z $NETWORK_RESOURCE_GROUP ]]; then echo "Please set NETWORK_RESOURCE_GROUP"; exit 1; fi
if [[ -z $SERVICE_PRINCIPAL_NAME ]]; then echo "Please set SERVICE_PRINCIPAL_NAME"; exit 1; fi


# login to azure
az login --service-principal -u http://$AZURE_SP_CI_USER -p $AZURE_SP_CI_PASSWORD --tenant $TENANT_ID
# set subscription
az account set --subscription $SUBSCRIPTION_ID
# delete resource groups
if [[ ! -z $(az group list | jq --arg rg "$PCF_RESOURCE_GROUP" '.[] | select(.name == $rg) | .name' | tr -d '"') ]]; then
  echo "Deleting resource group $PCF_RESOURCE_GROUP ..."
  az group delete -n $PCF_RESOURCE_GROUP -y
  echo "Deleting resource group $PCF_RESOURCE_GROUP Done."
else
  echo "Resource group $PCF_RESOURCE_GROUP does not exist. Skipping delete"
fi
if [[ ! -z $(az group list | jq --arg rg "$NETWORK_RESOURCE_GROUP" '.[] | select(.name == $rg) | .name' | tr -d '"') ]]; then
  echo "Deleting resource group $NETWORK_RESOURCE_GROUP ..."
  az group delete -n $NETWORK_RESOURCE_GROUP -y
  echo "Deleting resource group $NETWORK_RESOURCE_GROUP Done."
else
  echo "Resource group $NETWORK_RESOURCE_GROUP does not exist. Skipping delete"
fi

echo "Begin $START_TIME"
echo "End `date`"
