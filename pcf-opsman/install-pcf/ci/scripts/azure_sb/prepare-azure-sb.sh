#!/bin/bash

set -ex	
START_TIME=`date`
echo "Begin $START_TIME"

if [[ -z $AZURE_SP_CI_USER ]]; then echo "Please set AZURE_SP_CI_USER"; exit 1; fi
if [[ -z $AZURE_SP_CI_PASSWORD ]]; then echo "Please set AZURE_SP_CI_PASSWORD"; exit 1; fi
if [[ -z $AZURE_SB_TENANT_ID ]]; then echo "Please set AZURE_SB_TENANT_ID"; exit 1; fi
if [[ -z $AZURE_SB_SUBSCRIPTION_ID ]]; then echo "Please set AZURE_SB_SUBSCRIPTION_ID"; exit 1; fi
if [[ -z $AZURE_SB_RESOURCE_GROUP ]]; then echo "Please set AZURE_SB_RESOURCE_GROUP"; exit 1; fi
if [[ -z $AZURE_SB_LOCATION ]]; then echo "Please set AZURE_SB_LOCATION"; exit 1; fi
if [[ -z $AZURE_SB_SERVICE_PRINCIPAL_NAME ]]; then echo "Please set AZURE_SB_RESOURCE_GROUP"; exit 1; fi
if [[ -z $AZURE_SB_DB_SERVER ]]; then echo "Please set AZURE_SB_DB_SERVER"; exit 1; fi
if [[ -z $AZURE_SB_SQL_SERVER_ADMIN_USER ]]; then echo "Please set AZURE_SB_SQL_SERVER_ADMIN_USER"; exit 1; fi
if [[ -z $AZURE_SB_SQL_SERVER_ADMIN_PASSWORD ]]; then echo "Please set AZURE_SB_SQL_SERVER_ADMIN_PASSWORD"; exit 1; fi
if [[ -z $AZURE_SB_DB_NAME ]]; then echo "Please set AZURE_SB_DB_NAME"; exit 1; fi

az login --service-principal -u http://$AZURE_SP_CI_USER -p $AZURE_SP_CI_PASSWORD -t $AZURE_SB_TENANT_ID 
az account set --subscription $AZURE_SB_SUBSCRIPTION_ID



if [[ -z $(az group list | jq --arg rg "$AZURE_SB_RESOURCE_GROUP" '.[] | select(.name == $rg) | .name' | tr -d '"') ]]; then
  echo "Creating resource group $AZURE_SB_RESOURCE_GROUP in $AZURE_SB_LOCATION"
  az group create -n "$AZURE_SB_RESOURCE_GROUP" -l "$AZURE_SB_LOCATION"
fi

# Assign contributor role to subscription - does not work with; looks like it works only for custom roles ?
#az role assignment create --role "Contributor" --assignee "http://$AZURE_SB_SERVICE_PRINCIPAL_NAME" --scope /subscriptions/$AZURE_SB_SUBSCRIPTION_ID/resourceGroups/$AZURE_SB_RESOURCE_GROUP

az provider register -n Microsoft.sql 

if [[ -z $(az sql server list -g $AZURE_SB_RESOURCE_GROUP | jq --arg SERVER_NAME "$AZURE_SB_DB_SERVER" '.[] | select(.name == $SERVER_NAME) | .name' | tr -d '"') ]]; then
  az sql server create -n $AZURE_SB_DB_SERVER -g $AZURE_SB_RESOURCE_GROUP -l $AZURE_SB_LOCATION -u "$AZURE_SB_SQL_SERVER_ADMIN_USER" -p "$AZURE_SB_SQL_SERVER_ADMIN_PASSWORD"
  az sql server firewall-rule create -n $AZURE_SB_DB_SERVER -g $AZURE_SB_RESOURCE_GROUP -s $AZURE_SB_DB_SERVER --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
  if [[ -z $(az sql db list -g $AZURE_SB_RESOURCE_GROUP -s $AZURE_SB_DB_SERVER | jq --arg DB_NAME "$AZURE_SB_DB_NAME" '.[] | select(.name == $DB_NAME) | .name' | tr -d '"') ]]; then
    az sql db create -s $AZURE_SB_DB_SERVER -g $AZURE_SB_RESOURCE_GROUP -n $AZURE_SB_DB_NAME
  fi
fi



echo "Begin $START_TIME"
echo "End `date`"
