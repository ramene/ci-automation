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

if [[ -z $PCF_RESOURCE_GROUP ]]; then echo "Please set PCF_RESOURCE_GROUP"; exit 1; fi
if [[ -z $NETWORK_RESOURCE_GROUP ]]; then echo "Please set NETWORK_RESOURCE_GROUP"; exit 1; fi
if [[ -z $AZURE_SB_RESOURCE_GROUP ]]; then echo "Please set AZURE_SB_RESOURCE_GROUP"; exit 1; fi
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




# create role and assign permission to network resource group
# this needs to execute after NETWORK_RESOURCE_GROUP is created. (i.e. after prepare-azure step is executed.
# Ideal place for this is prepare azure script. However, the service principal accounts does not have authorization to create role definitions/assignments.
# OR create NETWORK_RESOURCE_GROUP here ?

# create resource groups
if [[ -z $(az group list | jq --arg rg "$PCF_RESOURCE_GROUP" '.[] | select(.name == $rg) | .name' | tr -d '"') ]]; then
  az group create -n "$PCF_RESOURCE_GROUP" -l "$AZURE_LOCATION"
fi
if [[ -z $(az group list | jq --arg rg "$NETWORK_RESOURCE_GROUP" '.[] | select(.name == $rg) | .name' | tr -d '"') ]]; then
  az group create -n "$NETWORK_RESOURCE_GROUP" -l "$AZURE_LOCATION"
fi
if [[ -z $(az group list | jq --arg rg "$AZURE_SB_RESOURCE_GROUP" '.[] | select(.name == $rg) | .name' | tr -d '"') ]]; then
  echo "Creating resource group $AZURE_SB_RESOURCE_GROUP in $AZURE_LOCATION"
  az group create -n "$AZURE_SB_RESOURCE_GROUP" -l "$AZURE_LOCATION"
fi




# Create Service Principal for running automation script. This service principal will be used to prepare azure for PCF installation
# This service principal will have contributor role pcf and network resource groups
### Begin ###
if [[ -z $(az ad app list | jq --arg spn "$CI_SERVICE_PRINCIPAL_NAME" '.[] | select(.displayName == $spn) | .displayName' | tr -d '"') ]]; then
  az ad app create --display-name "$CI_SERVICE_PRINCIPAL_NAME" \
          --password "$CI_CLIENT_SECRET" \
          --identifier-uris 'http://'"$CI_SERVICE_PRINCIPAL_NAME" \
          --homepage 'http://'"$CI_SERVICE_PRINCIPAL_NAME" | jq '.appId' | tr -d '"'
  sleep 30
fi

CI_APPLICATION_ID=$(az ad app list --display-name $CI_SERVICE_PRINCIPAL_NAME | jq '.[] | .appId' | tr -d '"')
if [[ -z $(az ad sp list --display-name $CI_SERVICE_PRINCIPAL_NAME | jq '.[] | .appId' | tr -d '"') ]]; then
  az ad sp create --id "$CI_APPLICATION_ID"
  sleep 30
fi

echo "CI_APPLICATION_ID = $CI_APPLICATION_ID"


if [[ -z $(az role assignment list --assignee http://$CI_SERVICE_PRINCIPAL_NAME | jq '.[] | .id' | tr -d '"') ]]; then
  az role assignment create --role "Contributor" --assignee "http://$CI_SERVICE_PRINCIPAL_NAME" --scope /subscriptions/$SUBSCRIPTION_ID
  az role assignment create --role "User Access Administrator" --assignee "http://$CI_SERVICE_PRINCIPAL_NAME" --scope /subscriptions/$SUBSCRIPTION_ID
#  az role assignment create --role "Owner" --assignee "http://$CI_SERVICE_PRINCIPAL_NAME" --scope /subscriptions/$SUBSCRIPTION_ID
fi


### End ###


# Create service principal to configure pcf. This service pricipal will be used to configure "Azure Config" in opsman.
### Begin ###
if [[ -z $(az ad app list | jq --arg spn "$PCF_SERVICE_PRINCIPAL_NAME" '.[] | select(.displayName == $spn) | .displayName' | tr -d '"') ]]; then
  az ad app create --display-name "$PCF_SERVICE_PRINCIPAL_NAME" \
          --password "$PCF_CLIENT_SECRET" \
          --identifier-uris 'http://'"$PCF_SERVICE_PRINCIPAL_NAME" \
          --homepage 'http://'"$PCF_SERVICE_PRINCIPAL_NAME" | jq '.appId' | tr -d '"'
  sleep 30
fi

PCF_APPLICATION_ID=$(az ad app list --display-name $PCF_SERVICE_PRINCIPAL_NAME | jq '.[] | .appId' | tr -d '"')
if [[ -z $(az ad sp list --display-name $PCF_SERVICE_PRINCIPAL_NAME | jq '.[] | .appId' | tr -d '"') ]]; then
  az ad sp create --id "$PCF_APPLICATION_ID"
  sleep 30
fi

echo "PCF_APPLICATION_ID = $PCF_APPLICATION_ID"





# assign contributor role to  PCF_SERVICE_PRINCIPAL_NAME in PCF_RESOURCE_GROUP

if [[ -z $(az role assignment list --role "Contributor" --assignee "http://$PCF_SERVICE_PRINCIPAL_NAME" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$PCF_RESOURCE_GROUP | jq '.[] | .id' | tr -d '"') ]]; then
  az role assignment create --role "Contributor" --assignee "http://$PCF_SERVICE_PRINCIPAL_NAME" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$PCF_RESOURCE_GROUP
fi

# create role and assign permission to network resource group
if [[ -z $(az role definition list --name $NET_RG_READ_ONLY_ROLE_NAME | jq '.[]') ]]; then
  BOSH_SP_ROLE_DEF=$(source $NET_RG_READ_ONLY_ROLE_DEF_FILE_NAME)
  az role definition create --role-definition "$BOSH_SP_ROLE_DEF"
fi

if [[ -z $(az role assignment list --role "$NET_RG_READ_ONLY_ROLE_NAME" --assignee "http://""$PCF_SERVICE_PRINCIPAL_NAME" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$NETWORK_RESOURCE_GROUP | jq '.[] | .id' | tr -d '"') ]]; then
  az role assignment create --role "$NET_RG_READ_ONLY_ROLE_NAME" --assignee "http://""$PCF_SERVICE_PRINCIPAL_NAME" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$NETWORK_RESOURCE_GROUP
fi


### End ###

# Create Service Principal for azure service broker. This service principal is used to configure azure service broker
### Begin ###
if [[ -z $(az ad app list | jq --arg spn "$AZURE_SB_SERVICE_PRINCIPAL_NAME" '.[] | select(.displayName == $spn) | .displayName' | tr -d '"') ]]; then
  az ad app create --display-name "$AZURE_SB_SERVICE_PRINCIPAL_NAME" \
          --password "$AZURE_SB_CLIENT_SECRET" \
          --identifier-uris 'http://'"$AZURE_SB_SERVICE_PRINCIPAL_NAME" \
          --homepage 'http://'"$AZURE_SB_SERVICE_PRINCIPAL_NAME" | jq '.appId' | tr -d '"'
  sleep 30
fi

AZURE_SB_APPLICATION_ID=$(az ad app list --display-name $AZURE_SB_SERVICE_PRINCIPAL_NAME | jq '.[] | .appId' | tr -d '"')
if [[ -z $(az ad sp list --display-name $AZURE_SB_SERVICE_PRINCIPAL_NAME | jq '.[] | .appId' | tr -d '"') ]]; then
  az ad sp create --id "$AZURE_SB_APPLICATION_ID"
  sleep 30
fi

echo "AZURE_SB_APPLICATION_ID = $AZURE_SB_APPLICATION_ID"

if [[ -z $(az role assignment list --assignee http://$AZURE_SB_SERVICE_PRINCIPAL_NAME | jq '.[] | .id' | tr -d '"') ]]; then
  az role assignment create --role "Contributor" --assignee "http://$AZURE_SB_SERVICE_PRINCIPAL_NAME" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$AZURE_SB_RESOURCE_GROUP
fi

### End ###


echo "#######################################################################################"
echo "CI_SERVICE_PRINCIPAL_NAME = $CI_SERVICE_PRINCIPAL_NAME"
echo "PCF_SERVICE_PRINCIPAL_NAME = $PCF_SERVICE_PRINCIPAL_NAME"
echo "AZURE_SB_SERVICE_PRINCIPAL_NAME = $AZURE_SB_SERVICE_PRINCIPAL_NAME"
echo "#######################################################################################"
