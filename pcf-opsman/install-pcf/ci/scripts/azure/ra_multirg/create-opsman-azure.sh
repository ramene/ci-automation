#!/bin/bash

set -e
START_TIME=`date`
echo "Begin $START_TIME"

# if first argument is passed, source it - used in jenkins builds
if [[ ! -z $1 ]]; then
  source $1
fi

if [[ -z $ORG ]]; then echo "Please set ORG"; exit 1; fi
if [[ -z $AZURE_SP_CI_USER ]]; then echo "Please set AZURE_SP_CI_USER"; exit 1; fi
if [[ -z $AZURE_SP_CI_PASSWORD ]]; then echo "Please set AZURE_SP_CI_PASSWORD"; exit 1; fi
if [[ -z $TENANT_ID ]]; then echo "Please set TENANT_ID"; exit 1; fi
if [[ -z $AZURE_LOCATION ]]; then echo "Please set AZURE_LOCATION"; exit 1; fi
if [[ -z $SUBSCRIPTION_ID ]]; then echo "Please set SUBSCRIPTION_ID"; exit 1; fi
if [[ -z $PCF_RESOURCE_GROUP ]]; then echo "Please set PCF_RESOURCE_GROUP"; exit 1; fi
if [[ -z $NETWORK_RESOURCE_GROUP ]]; then echo "Please set NETWORK_RESOURCE_GROUP"; exit 1; fi
if [[ -z $BOSH_STORAGE_NAME ]]; then echo "Please set BOSH_STORAGE_NAME"; exit 1; fi
if [[ -z $OPSMAN_VERSION ]]; then echo "Please set OPSMAN_VERSION"; exit 1; fi
if [[ -z $OPS_MAN_IMAGE_URL ]]; then echo "Please set OPS_MAN_IMAGE_URL"; exit 1; fi
if [[ -z $OPSMAN_VM_NAME ]]; then echo "Please set OPSMAN_VM_NAME"; exit 1; fi
if [[ -z $OPSMAN_OS_DISK_SIZE ]]; then echo "Please set OPSMAN_OS_DISK_SIZE"; exit 1; fi
if [[ -z $OPSMAN_VM_USER ]]; then echo "Please set OPSMAN_VM_USER"; exit 1; fi
if [[ -z $OPS_MAN_PUBLIC_KEY ]]; then echo "Please set OPS_MAN_PUBLIC_KEY"; exit 1; fi
if [[ -z $VNET_NAME ]]; then echo "Please set VNET_NAME"; exit 1; fi
if [[ -z $INFRA_SUBNET_NAME ]]; then echo "Please set INFRA_SUBNET_NAME"; exit 1; fi
if [[ -z $OPSMGR_NSG ]]; then echo "Please set OPSMGR_NSG"; exit 1; fi
if [[ -z $OPSMAN_PRIVATE_IP ]]; then echo "Please set OPSMAN_PRIVATE_IP"; exit 1; fi
if [[ -z $OPSMAN_PIP_NAME ]]; then echo "Please set OPSMAN_PIP_NAME"; exit 1; fi

# login to azure
# az login -u $AZURE_CLI_USER -p $AZURE_CLI_PASSWORD
az login --service-principal -u http://$AZURE_SP_CI_USER -p $AZURE_SP_CI_PASSWORD --tenant $TENANT_ID

# set subscription
az account set --subscription $SUBSCRIPTION_ID

BS_NAME="$BOSH_STORAGE_NAME""$ORG"
BOSH_STORAGE_CONNECTION_STRING="$(az storage account show-connection-string -g $PCF_RESOURCE_GROUP -n $BS_NAME | jq .connectionString | tr -d '"')"
OUTPUT_CHECK=true
if [[ -z $(az storage blob show -c opsmanager -n opsman_$OPSMAN_VERSION.vhd --connection-string $BOSH_STORAGE_CONNECTION_STRING | jq .properties.copy.status | grep -i -E "pending|success" | tr -d '"') ]]; then
    echo "Starting VHD upload..."
    az storage blob copy start \
        --source-uri "$OPS_MAN_IMAGE_URL" \
        --destination-container opsmanager \
        --connection-string "$BOSH_STORAGE_CONNECTION_STRING" \
        --destination-blob opsman_$OPSMAN_VERSION.vhd
else
    echo "Skipping Ops Manager image upload. Image opsman_$OPSMAN_VERSION.vhd already exists"
    if [[ ! -z $(az storage blob show -c opsmanager -n opsman_$OPSMAN_VERSION.vhd --connection-string $BOSH_STORAGE_CONNECTION_STRING | jq .properties.copy.status | grep -i "success" |tr -d '"') ]]; then
        OUTPUT_CHECK=false
    fi
fi

echo "check for copy status $OUTPUT_CHECK"

# Loop and wait for upload to finish (takes some time)
while [ "$OUTPUT_CHECK" = true ]; do
    if [[ -z $(az storage blob show -c opsmanager -n opsman_$OPSMAN_VERSION.vhd --connection-string $BOSH_STORAGE_CONNECTION_STRING | jq .properties.copy.status | grep -i "pending" |tr -d '"') ]]; then
        OUTPUT_CHECK=false
    else
        COPY_OUTPUT=$(az storage blob show -c opsmanager -n opsman_$OPSMAN_VERSION.vhd --connection-string $BOSH_STORAGE_CONNECTION_STRING | jq .properties.copy.progress |tr -d '"')
    fi
    echo "Still uploading... $COPY_OUTPUT"
    sleep 5
done

# Create Ops Man public ip
if [[ -z $(az network public-ip show -g "$NETWORK_RESOURCE_GROUP" -n "$OPSMAN_PIP_NAME"  | jq .name | tr -d '"') ]]; then
  az network public-ip create -g "$NETWORK_RESOURCE_GROUP" -n "$OPSMAN_PIP_NAME" -l "$AZURE_LOCATION" --allocation-method Static
fi
OPSMAN_PIP_ID=$(az network public-ip show -g "$NETWORK_RESOURCE_GROUP" -n "$OPSMAN_PIP_NAME" | jq .id | tr -d '"')

# Create ops man nic
OPSMAN_NIC_NAME=opsman_${OPSMAN_VERSION//./}
if [[ -z $(az network nic show -n $OPSMAN_NIC_NAME -g $PCF_RESOURCE_GROUP | jq .name | tr -d '"') ]]; then
    echo "Creating OpsMan nic $OPSMAN_NIC_NAME ..."
    SUBNET_ID=$(az network vnet subnet show -n $INFRA_SUBNET_NAME -g $NETWORK_RESOURCE_GROUP --vnet-name $VNET_NAME | jq .id | tr -d '"')
    az network nic create \
        --name "$OPSMAN_NIC_NAME" \
        --resource-group "$PCF_RESOURCE_GROUP" \
        --location "$AZURE_LOCATION" \
	--subnet $SUBNET_ID \
        --network-security-group "$OPSMGR_NSG" \
        --private-ip-address "$OPSMAN_PRIVATE_IP" \
        --public-ip-address "$OPSMAN_PIP_ID"
else
    echo "Skipping nic create. Nic $OPSMAN_NIC_NAME already exists"
fi

OM_VM_NAME=${OPSMAN_VM_NAME}${OPSMAN_VERSION//./}
if [[ -z $(az vm get-instance-view -g $PCF_RESOURCE_GROUP -n $OM_VM_NAME | jq '.instanceView.statuses[] | select(.code == "ProvisioningState/succeeded") | .code' | tr -d '"') ]]; then
  echo "Creating OpsMan VM..."
  az vm create --resource-group "$PCF_RESOURCE_GROUP" \
	--name "$OM_VM_NAME" \
	--location "$AZURE_LOCATION" \
	--os-type Linux \
	--nics "$OPSMAN_NIC_NAME" \
	--os-disk-name osdisk$OPSMAN_VERSION \
	--image https://"$BS_NAME".blob.core.windows.net/opsmanager/opsman_$OPSMAN_VERSION.vhd \
	--admin-username "$OPSMAN_VM_USER" \
	--storage-account "$BS_NAME" \
	--size Standard_DS2_v2 \
	--ssh-key-value "$OPS_MAN_PUBLIC_KEY" \
	--use-unmanaged-disk
else
  echo "Ops man vm already exists. Skiping create vm ..."
fi




# Re-size the OS disk
if [[ "$(az vm show -g $PCF_RESOURCE_GROUP -n $OM_VM_NAME | jq .storageProfile.osDisk.diskSizeGb)" -ne "$OPSMAN_OS_DISK_SIZE" ]]; then
  echo "Re-sizing Opsman OS disk..."
  az vm deallocate -g "$PCF_RESOURCE_GROUP" -n "$OM_VM_NAME"
  az vm update  -g "$PCF_RESOURCE_GROUP" -n "$OM_VM_NAME" --set storageProfile.osDisk.diskSizeGb="$OPSMAN_OS_DISK_SIZE"
else
  echo "Skipping Opsman OS Disk resizing..."	
fi

if [[ -z $(az vm get-instance-view -g $PCF_RESOURCE_GROUP -n $OM_VM_NAME | jq '.instanceView.statuses[] | select(.code == "PowerState/running") | .code' | tr -d '"') ]]; then
  echo "Starting opsman vm ..."
  az vm start -g "$PCF_RESOURCE_GROUP" -n "$OM_VM_NAME"
else
  echo "Opsman vm already started. skipping start."
fi

OPSMAN_PIP=$(az network public-ip show -g "$NETWORK_RESOURCE_GROUP" -n "$OPSMAN_PIP_NAME" | jq .ipAddress | tr -d '"')

echo "#########################################################################################################################"
echo "Create A record for $OPSMAN_HOST with ip address $OPSMAN_PIP"
echo "#########################################################################################################################"


