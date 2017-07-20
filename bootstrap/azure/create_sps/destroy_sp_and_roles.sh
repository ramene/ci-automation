#!/bin/bash

set -ex


# This scrip assumes that user has already logged in using azure cli
# 1. Create service principal for running automation scripts
# 2. Create service principal for configuring PCF
# 3. Create service pricipal to configure azure service broker


if [[ -z $1 ]]; then
  echo "Please pass variables file. Usage create_sp_and_roles.sh <VARIABLE_FILE>"
  exit
fi

source $1

if [[ -z $NETWORK_RESOURCE_GROUP ]]; then echo "Please set NETWORK_RESOURCE_GROUP"; exit 1; fi
if [[ -z $AZURE_LOCATION ]]; then echo "Please set AZURE_LOCATION"; exit 1; fi

if [[ -z $SUBSCRIPTION_ID ]]; then echo "Please set SUBSCRIPTION_ID"; exit 1; fi
if [[ -z $PCF_SERVICE_PRINCIPAL_NAME ]]; then echo "Please set PCF_SERVICE_PRINCIPAL_NAME"; exit 1; fi
if [[ -z $PCF_CLIENT_SECRET ]]; then echo "Please set PCF_CLIENT_SECRET"; exit 1; fi
if [[ -z $NET_RG_READ_ONLY_ROLE_NAME ]]; then echo "Please set NET_RG_READ_ONLY_ROLE_NAME"; exit 1; fi
if [[ -z $NET_RG_READ_ONLY_ROLE_DEF_FILE_NAME ]]; then echo "Please set NET_RG_READ_ONLY_ROLE_DEF_FILE_NAME"; exit 1; fi

if [[ -z $CI_SERVICE_PRINCIPAL_NAME ]]; then echo "Please set CI_SERVICE_PRINCIPAL_NAME"; exit 1; fi
if [[ -z $CI_CLIENT_SECRET ]]; then echo "Please set CI_CLIENT_SECRET"; exit 1; fi

if [[ -z $AZURE_SB_SERVICE_PRINCIPAL_NAME ]]; then echo "Please set AZURE_SB_SERVICE_PRINCIPAL_NAME"; exit 1; fi
if [[ -z $AZURE_SB_CLIENT_SECRET ]]; then echo "Please set AZURE_SB_CLIENT_SECRET"; exit 1; fi


az ad app delete --id http://$CI_SERVICE_PRINCIPAL_NAME
az ad app delete --id http://$PCF_SERVICE_PRINCIPAL_NAME
az role assignment delete -g $NETWORK_RESOURCE_GROUP --role $NET_RG_READ_ONLY_ROLE_NAME
az role definition delete --name $NET_RG_READ_ONLY_ROLE_NAME
az ad app delete --id http://$AZURE_SB_SERVICE_PRINCIPAL_NAME
