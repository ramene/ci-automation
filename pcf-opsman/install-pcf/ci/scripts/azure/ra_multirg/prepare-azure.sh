#!/bin/bash
set -ex

START_TIME=`date`
echo "Begin $START_TIME"
# if first argument is passed, source it - used in jenkins builds
if [[ ! -z $1 ]]; then
  source $1
fi

# check for required variables
if [[ -z $ORG ]]; then echo "Please set ORG"; exit 1; fi
if [[ -z $AZURE_SP_CI_USER ]]; then echo "Please set AZURE_SP_CI_USER"; exit 1; fi
if [[ -z $AZURE_SP_CI_PASSWORD ]]; then echo "Please set AZURE_SP_CI_PASSWORD"; exit 1; fi
if [[ -z $TENANT_ID ]]; then echo "Please set TENANT_ID"; exit 1; fi
if [[ -z $SUBSCRIPTION_ID ]]; then echo "Please set SUBSCRIPTION_ID"; exit 1; fi
if [[ -z $AZURE_LOCATION ]]; then echo "Please set AZURE_LOCATION"; exit 1; fi
if [[ -z $PCF_RESOURCE_GROUP ]]; then echo "Please set PCF_RESOURCE_GROUP"; exit 1; fi
if [[ -z $NETWORK_RESOURCE_GROUP ]]; then echo "Please set NETWORK_RESOURCE_GROUP"; exit 1; fi
if [[ -z $SERVICE_PRINCIPAL_NAME ]]; then echo "Please set SERVICE_PRINCIPAL_NAME"; exit 1; fi
if [[ -z $CLIENT_SECRET ]]; then echo "Please set CLIENT_SECRET"; exit 1; fi
if [[ -z $NET_RG_READ_ONLY_ROLE_NAME ]]; then echo "Please set NET_RG_READ_ONLY_ROLE_NAME"; exit 1; fi
if [[ -z $BOSH_SP_ROLE_DEF_FILE_NAME ]]; then echo "Please set BOSH_SP_ROLE_DEF_FILE_NAME"; exit 1; fi
if [[ -z $BOSH_STORAGE_NAME ]]; then echo "Please set BOSH_STORAGE_NAME"; exit 1; fi
if [[ -z $DEPLOYMENT_STORAGE_NAME ]]; then echo "Please set DEPLOYMENT_STORAGE_NAME"; exit 1; fi
if [[ -z $DEPLOYMENT_STORAGE_ACCOUNT_COUNT ]]; then echo "Please set OPSMAN_STORAGE_ACCOUNT_COUNT"; exit 1; fi
if [[ -z $VNET_NAME ]]; then echo "Please set VNET_NAME"; exit 1; fi
if [[ -z $VNET_CIDR ]]; then echo "Please set VNET_CIDR"; exit 1; fi
if [[ -z $NETWORKS_DNS ]]; then echo "Please set NETWORKS_DNS"; exit 1; fi
if [[ -z $INFRA_SUBNET_NAME ]]; then echo "Please set INFRA_SUBNET_NAME"; exit 1; fi
if [[ -z $INFRA_NETWORK_CIDR ]]; then echo "Please set INFRA_NETWORK_CIDR"; exit 1; fi
if [[ -z $PCF_SUBNET_NAME ]]; then echo "Please set PCF_SUBNET_NAME"; exit 1; fi
if [[ -z $PCF_NETWORK_CIDR ]]; then echo "Please set PCF_NETWORK_CIDR"; exit 1; fi
if [[ -z $SERVICES_SUBNET_NAME ]]; then echo "Please set SERVICES_SUBNET_NAME"; exit 1; fi
if [[ -z $SERVICES_NETWORK_CIDR ]]; then echo "Please set SERVICES_NETWORK_CIDR"; exit 1; fi
if [[ -z $DYNAMIC_SERVICES_SUBNET_NAME ]]; then echo "Please set DYNAMIC_SERVICES_SUBNET_NAME"; exit 1; fi
if [[ -z $DYNAMIC_SERVICES_NETWORK_CIDR ]]; then echo "Please set DYNAMIC_SERVICES_NETWORK_CIDR"; exit 1; fi
if [[ -z $OPSMGR_NSG ]]; then echo "Please set OPSMGR_NSG"; exit 1; fi
if [[ -z $PCF_NSG ]]; then echo "Please set PCF_NSG"; exit 1; fi
if [[ -z $ALB_NAME ]]; then echo "Please set ALB_NAME"; exit 1; fi
if [[ -z $ALB_PIP_NAME ]]; then echo "Please set ALB_PIP_NAME"; exit 1; fi

# login to azure
# az login -u $AZURE_CLI_USER -p $AZURE_CLI_PASSWORD
az login --service-principal -u http://$AZURE_SP_CI_USER -p $AZURE_SP_CI_PASSWORD --tenant $TENANT_ID
# set subscription
az account set --subscription $SUBSCRIPTION_ID

# Create resource group if needed - redundant as resource groups are created in the create_sp_and_roles.sh script
if [[ -z $(az group list | jq --arg rg "$PCF_RESOURCE_GROUP" '.[] | select(.name == $rg) | .name' | tr -d '"') ]]; then
  az group create -n "$PCF_RESOURCE_GROUP" -l "$AZURE_LOCATION"
fi
if [[ -z $(az group list | jq --arg rg "$NETWORK_RESOURCE_GROUP" '.[] | select(.name == $rg) | .name' | tr -d '"') ]]; then
  az group create -n "$NETWORK_RESOURCE_GROUP" -l "$AZURE_LOCATION"
fi

# Assign contributor role to subscription - 
#az role assignment create --role "Contributor" --assignee "http://$SERVICE_PRINCIPAL_NAME" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$PCF_RESOURCE_GROUP

# create role and assign permission to network resource group
#if [[ -z $(az role definition list --name $NET_RG_READ_ONLY_ROLE_NAME | jq '.[]') ]]; then
#  BOSH_SP_ROLE_DEF=$(source $BOSH_SP_ROLE_DEF_FILE_NAME)
#  az role definition create --role-definition "$BOSH_SP_ROLE_DEF"
#  az role assignment create --role "$NET_RG_READ_ONLY_ROLE_NAME" --assignee "http://""$SERVICE_PRINCIPAL_NAME" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$NETWORK_RESOURCE_GROUP
#fi


##### Create storage accounts - Begin

# Create BOSH storage account - to be configured in Ops Man -> Azure Config -> BOSH Storage Account Name
BS_NAME="$BOSH_STORAGE_NAME""$ORG"
if [[ -z $(az storage account show -n $BS_NAME -g $PCF_RESOURCE_GROUP | jq '.name' | tr -d '"') ]]; then
  echo "Creating $BS_NAME in resource group $PCF_RESOURCE_GROUP"
  az storage account create -n "$BS_NAME" -g "$PCF_RESOURCE_GROUP" --sku Standard_LRS --kind Storage -l "$AZURE_LOCATION"
  BOSH_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string -g $PCF_RESOURCE_GROUP -n $BS_NAME | jq .connectionString | tr -d '"')
  az storage container create -n opsmanager --connection-string "$BOSH_STORAGE_CONNECTION_STRING"
  az storage container create -n bosh --connection-string "$BOSH_STORAGE_CONNECTION_STRING"
  az storage container create -n stemcell --public-access blob --connection-string "$BOSH_STORAGE_CONNECTION_STRING"
  az storage table create -n stemcells  --connection-string "$BOSH_STORAGE_CONNECTION_STRING"
fi


# Create deployment storage accounts - to be configured in Ops Man -> Azure Config -> Deployments Storage Account Name (should be entered as "*$DEPLOYMENT_STORAGE_NAME*")
for i in $(seq 1 $DEPLOYMENT_STORAGE_ACCOUNT_COUNT); do
  DS_NAME="$DEPLOYMENT_STORAGE_NAME""$ORG""$i"
  if [[ -z $(az storage account show -n "$DS_NAME" -g $PCF_RESOURCE_GROUP | jq '.name' | tr -d '"') ]]; then
    echo "Creating $DS_NAME in resource group $PCF_RESOURCE_GROUP"
    az storage account create -n "$DS_NAME" -g "$PCF_RESOURCE_GROUP" --sku Standard_LRS --kind Storage -l "$AZURE_LOCATION"
    OPSMAN_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string -g $PCF_RESOURCE_GROUP -n "$DS_NAME" | jq .connectionString | tr -d '"')
    az storage container create -n opsmanager --connection-string "$OPSMAN_STORAGE_CONNECTION_STRING"
    az storage container create -n bosh --connection-string "$OPSMAN_STORAGE_CONNECTION_STRING"
    az storage container create -n stemcell --public-access blob --connection-string "$OPSMAN_STORAGE_CONNECTION_STRING"
  fi 
done
##### Create storage accounts - End


# Create VNET
if [[ -z $(az network vnet show -n $VNET_NAME -g $NETWORK_RESOURCE_GROUP | jq '.name' | tr -d '"') ]]; then
  az network vnet create -n "$VNET_NAME" --address-prefix "$VNET_CIDR" -g "$NETWORK_RESOURCE_GROUP" -l "$AZURE_LOCATION" --dns-servers "$NETWORKS_DNS"
  # Create subnets
  az network vnet subnet create -n "$INFRA_SUBNET_NAME" \
    -g "$NETWORK_RESOURCE_GROUP" \
    --address-prefix "$INFRA_NETWORK_CIDR" \
    --vnet-name "$VNET_NAME" 
  az network vnet subnet create -n "$PCF_SUBNET_NAME" \
    -g "$NETWORK_RESOURCE_GROUP" \
    --address-prefix "$PCF_NETWORK_CIDR" \
    --vnet-name "$VNET_NAME"
  az network vnet subnet create -n "$SERVICES_SUBNET_NAME" \
    -g "$NETWORK_RESOURCE_GROUP" \
    --address-prefix "$SERVICES_NETWORK_CIDR" \
    --vnet-name "$VNET_NAME"
  az network vnet subnet create -n "$DYNAMIC_SERVICES_SUBNET_NAME" \
    -g "$NETWORK_RESOURCE_GROUP" \
    --address-prefix "$DYNAMIC_SERVICES_NETWORK_CIDR" \
    --vnet-name "$VNET_NAME"
fi



# Create NSG for ops manager and rules if needed
if [[ -z $(az network nsg show -n $OPSMGR_NSG -g $PCF_RESOURCE_GROUP | jq '.name' | tr -d '"') ]]; then
  echo "Creating Network Security Group $OPSMGR_NSG ..."
  az network nsg create -g "$PCF_RESOURCE_GROUP" -l "$AZURE_LOCATION" -n "$OPSMGR_NSG"
  # Allow ssh to infra network(opsman) from internal network
  az network nsg rule create -n "opsman-https" \
    -g "$PCF_RESOURCE_GROUP" \
    --nsg-name "$OPSMGR_NSG" \
    --access Allow \
    --protocol Tcp \
    --direction Inbound \
    --priority 200 \
    --source-address-prefix "Internet" \
    --source-port-range '*' \
    --destination-address-prefix "$INFRA_NETWORK_CIDR" \
    --destination-port-range 443
  # Allow ssh to infra network from internal network
  az network nsg rule create -n "opsman-ssh" \
    -g "$PCF_RESOURCE_GROUP" \
    --nsg-name "$OPSMGR_NSG" \
    --access Allow \
    --protocol Tcp \
    --direction Inbound \
    --priority 300 \
    --source-address-prefix "Internet" \
    --source-port-range '*' \
    --destination-address-prefix "$INFRA_NETWORK_CIDR" \
    --destination-port-range 22
  # Allow access to other subnets from infra 
  echo "Creating rules for $INTERNAL_NETWORK network in $OPSMGR_NSG Network Security Group Done."
  az network nsg rule create -n 'opsman-to-vnet' \
    -g "$PCF_RESOURCE_GROUP" \
    --nsg-name "$OPSMGR_NSG" \
    --access Allow \
    --protocol '*' \
    --direction Inbound \
    --priority 400 \
    --source-address-prefix "$INFRA_NETWORK_CIDR" \
    --source-port-range '*' \
    --destination-address-prefix "$VNET_CIDR" \
    --destination-port-range '*'
    # --source-address-prefix $INFRA_NETWORK_CIDR \

  echo "Creating Network Security Group $OPSMGR_NSG Done."
fi


# this will be applied to ALB
if [[ -z $(az network nsg show -n $PCF_NSG -g $PCF_RESOURCE_GROUP | jq '.name' | tr -d '"') ]]; then
  echo "Creating Network Security Group $PCF_NSG ..."
  az network nsg create -g "$PCF_RESOURCE_GROUP" -l "$AZURE_LOCATION" -n "$PCF_NSG"
  echo "Creating rules for app access in $PCF_NSG Network Security Group ..."
  az network nsg rule create -n 'app-access' \
    -g "$PCF_RESOURCE_GROUP" \
    --nsg-name "$PCF_NSG" \
    --access Allow \
    --protocol Tcp \
    --direction Inbound \
    --priority 100 \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range '*'
  echo "Creating Network Security Group $PCF_NSG Done"
fi
echo "NSGs created."



# create public ip for ALB
if [[ -z $(az network public-ip show -g "$NETWORK_RESOURCE_GROUP" -n "$ALB_PIP_NAME"  | jq .name | tr -d '"' | grep $ALB_PIP_NAME) ]]; then
  az network public-ip create -g "$NETWORK_RESOURCE_GROUP" -n "$ALB_PIP_NAME" -l "$AZURE_LOCATION" --allocation-method Static
fi

ALB_PIP_ID=$(az network public-ip show -g "$NETWORK_RESOURCE_GROUP" -n "$ALB_PIP_NAME" | jq .id | tr -d '"')

##### Create load balancers if needed
if [[ -z $(az network lb show -n $ALB_NAME -g $PCF_RESOURCE_GROUP | jq .name | tr -d '"') ]]; then
  # Create External Load Balancer
  BACKEND_POOL_NAME=gorouters
  az network lb create -g "$PCF_RESOURCE_GROUP" \
    -n "$ALB_NAME" \
    -l "$AZURE_LOCATION"  \
    --frontend-ip-name "$ALB_NAME"-feip \
    --public-ip-address "$ALB_PIP_ID" \
    --backend-pool-name $BACKEND_POOL_NAME

  # Add probes/backend pools
  az network lb probe create -n tcp -g "$PCF_RESOURCE_GROUP" \
    --lb-name "$ALB_NAME" \
    --protocol Tcp \
    --port 80
  az network lb rule create -n http -g "$PCF_RESOURCE_GROUP" \
    --lb-name "$ALB_NAME" \
    --protocol tcp \
    --frontend-ip-name "$ALB_NAME"-feip \
    --frontend-port 80 \
    --backend-pool-name $BACKEND_POOL_NAME \
    --backend-port 80
  az network lb rule create -n https -g "$PCF_RESOURCE_GROUP" \
    --lb-name "$ALB_NAME" \
    --protocol tcp \
    --frontend-ip-name "$ALB_NAME"-feip \
    --frontend-port 443 \
    --backend-pool-name $BACKEND_POOL_NAME \
    --backend-port 443
fi

echo "Begin $START_TIME"
echo "End `date`"
