#!/bin/bash

set -ex


if [[ -z $AZURE_SP_CI_USER ]]; then echo "Please set AZURE_SP_CI_USER"; exit 1; fi
if [[ -z $AZURE_SP_CI_PASSWORD ]]; then echo "Please set AZURE_SP_CI_PASSWORD"; exit 1; fi
if [[ -z $TENANT_ID ]]; then echo "Please set TENANT_ID"; exit 1; fi
if [[ -z $SUBSCRIPTION_ID ]]; then echo "Please set SUBSCRIPTION_ID"; exit 1; fi
if [[ -z $PCF_RESOURCE_GROUP ]]; then echo "Please set PCF_RESOURCE_GROUP"; exit 1; fi
if [[ -z $AZURE_LOCATION ]]; then echo "Please set AZURE_LOCATION"; exit 1; fi
if [[ -z $VNET_NAME ]]; then echo "Please set VNET_NAME"; exit 1; fi
if [[ -z $INFRA_SUBNET_NAME ]]; then echo "Please set INFRA_SUBNET_NAME"; exit 1; fi
if [[ -z $NETWORK_RESOURCE_GROUP ]]; then echo "Please set NETWORK_RESOURCE_GROUP"; exit 1; fi
if [[ -z $DNS_IMAGE_URN ]]; then echo "Please set DNS_IMAGE_URN"; exit 1; fi
if [[ -z $DNS_VM_USER ]]; then echo "Please set DNS_VM_USER"; exit 1; fi
if [[ -z $BOSH_STORAGE_NAME ]]; then echo "Please set BOSH_STORAGE_NAME"; exit 1; fi
if [[ -z $DNS_SERVER_PRIVATE_KEY ]]; then echo "Please set DNS_SERVER_PRIVATE_KEY"; exit 1; fi
if [[ -z $DNS_PUBLIC_KEY ]]; then echo "Please set DNS_PUBLIC_KEY"; exit 1; fi
if [[ -z $DNS_VM_NAME1 ]]; then echo "Please set DNS_VM_NAME1"; exit 1; fi
if [[ -z $DNS_NIC_NAME1 ]]; then echo "Please set DNS_NIC_NAME1"; exit 1; fi
if [[ -z $DNS_PRIVATE_IP1 ]]; then echo "Please set DNS_PRIVATE_IP1"; exit 1; fi
if [[ -z $DNS_VM_NAME2 ]]; then echo "Please set DNS_VM_NAME2"; exit 1; fi
if [[ -z $DNS_NIC_NAME2 ]]; then echo "Please set DNS_NIC_NAME2"; exit 1; fi
if [[ -z $DNS_PRIVATE_IP2 ]]; then echo "Please set DNS_PRIVATE_IP2"; exit 1; fi
if [[ -z $TOP_LEVEL_DOMAIN ]]; then echo "Please set TOP_LEVEL_DOMAIN"; exit 1; fi
if [[ -z $OPSMAN_DOMAIN ]]; then echo "Please set OPSMAN_DOMAIN"; exit 1; fi
if [[ -z $OPSMAN_PRIVATE_IP ]]; then echo "Please set OPSMAN_PRIVATE_IP"; exit 1; fi

DNS_SERVER_PRIVATE_KEY_FILE=dnsKey
DNS_PUBLIC_KEY_FILE=dnsKey.pub
echo "$DNS_SERVER_PRIVATE_KEY" > dnsKey
echo "$DNS_PUBLIC_KEY" > dnsKey.pub
chmod 400 dnsKey

DNS_PIP_NAME1=dnsserverpip1
DNS_PIP_NAME2=dnsserverpip2


az login --service-principal -u http://$AZURE_SP_CI_USER -p $AZURE_SP_CI_PASSWORD --tenant $TENANT_ID
# set subscription
az account set --subscription $SUBSCRIPTION_ID

ALB_PIP=$(az network public-ip show -g "$NETWORK_RESOURCE_GROUP" -n "$ALB_PIP_NAME" | jq .ipAddress | tr -d '"')

# Create DNS server1 public ip
if [[ -z $(az network public-ip show -g "$NETWORK_RESOURCE_GROUP" -n "$DNS_PIP_NAME1"  | jq .name | tr -d '"') ]]; then
  az network public-ip create -g "$NETWORK_RESOURCE_GROUP" -n "$DNS_PIP_NAME1" -l "$AZURE_LOCATION" --allocation-method Static
fi

DNS_PIP_ID1=$(az network public-ip show -g "$NETWORK_RESOURCE_GROUP" -n "$DNS_PIP_NAME1" | jq .id | tr -d '"')
DNS_PIP_1=$(az network public-ip show -g "$NETWORK_RESOURCE_GROUP" -n "$DNS_PIP_NAME1" | jq .ipAddress | tr -d '"')

# Create NIC for dns server1
if [[ -z $(az network nic show -n $DNS_NIC_NAME1 -g $PCF_RESOURCE_GROUP | jq .name | tr -d '"') ]]; then
    echo "Creating nic for $DNS_VM_NAME1 ..."
    SUBNET_ID=$(az network vnet subnet show -n $INFRA_SUBNET_NAME -g $NETWORK_RESOURCE_GROUP --vnet-name $VNET_NAME | jq .id | tr -d '"')
    az network nic create \
        --name "$DNS_NIC_NAME1" \
        --resource-group "$PCF_RESOURCE_GROUP" \
        --location "$AZURE_LOCATION" \
	--subnet $SUBNET_ID \
        --private-ip-address "$DNS_PRIVATE_IP1" \
        --public-ip-address "$DNS_PIP_ID1"
else
    echo "Skipping nic create. Nic $DNS_NIC_NAME1 already exists."
fi

# Create dns server1
if [[ -z $(az vm show -n "$DNS_VM_NAME1" -g "$PCF_RESOURCE_GROUP"  | jq .name | tr -d '"') ]]; then
    echo "Creating vm $DNS_VM_NAME1 ..."
    az vm create --resource-group "$PCF_RESOURCE_GROUP" \
        --name "$DNS_VM_NAME1" \
	--location "$AZURE_LOCATION" \
	--nics "$DNS_NIC_NAME1" \
	--image "$DNS_IMAGE_URN" \
	--admin-username "$DNS_VM_USER" \
	--storage-account "$BOSH_STORAGE_NAME" \
	--size Standard_DS2_v2 \
	--ssh-key-value "$DNS_PUBLIC_KEY_FILE" \
	--use-unmanaged-disk
else
    echo "Skipping vm create. vm $DNS_VM_NAME1 already exists."
fi

echo "Configuring dnsmasq in $DNS_VM_NAME1, NOT using jumpbox ...."
# Following assumes that dns servers have access to internet
#ssh -i $DNS_SERVER_PRIVATE_KEY_FILE -o StrictHostKeyChecking=no ${DNS_VM_USER}@$DNS_PRIVATE_IP1 'sudo apt-get update && sudo apt-get install -y dnsmasq && echo \"address=/$TOP_LEVEL_DOMAIN/$ALB_PIP\" | sudo tee --append /etc/dnsmasq.conf && sudo service dnsmasq restart'
#ssh -i $DNS_SERVER_PRIVATE_KEY_FILE -o StrictHostKeyChecking=no ${DNS_VM_USER}@$DNS_PRIVATE_IP1 'ho \"address=/$OPSMAN_DOMAIN/$OPSMAN_PRIVATE_IP\" | sudo tee --append /etc/dnsmasq.conf && sudo service dnsmasq restart'
ssh -i $DNS_SERVER_PRIVATE_KEY_FILE -o StrictHostKeyChecking=no ${DNS_VM_USER}@$DNS_PIP_1 "sudo apt-get update && sudo apt-get install -y dnsmasq && echo \"address=/$TOP_LEVEL_DOMAIN/$ALB_PIP\" | sudo tee --append /etc/dnsmasq.conf && sudo service dnsmasq restart"
ssh -i $DNS_SERVER_PRIVATE_KEY_FILE -o StrictHostKeyChecking=no ${DNS_VM_USER}@$DNS_PIP_1 "sudo echo \"address=/$OPSMAN_DOMAIN/$OPSMAN_PRIVATE_IP\" | sudo tee --append /etc/dnsmasq.conf && sudo service dnsmasq restart"
ssh -i $DNS_SERVER_PRIVATE_KEY_FILE -o StrictHostKeyChecking=no ${DNS_VM_USER}@$DNS_PIP_1 "sudo echo \"address=/$DNS_SYSTEM_DOMAIN/$ALB_PIP\" | sudo tee --append /etc/dnsmasq.conf && sudo service dnsmasq restart"
ssh -i $DNS_SERVER_PRIVATE_KEY_FILE -o StrictHostKeyChecking=no ${DNS_VM_USER}@$DNS_PIP_1 "sudo echo \"address=/$DNS_APPS_DOMAIN/$ALB_PIP\" | sudo tee --append /etc/dnsmasq.conf && sudo service dnsmasq restart"



# Create DNS server2 public ip
if [[ -z $(az network public-ip show -g "$NETWORK_RESOURCE_GROUP" -n "$DNS_PIP_NAME2"  | jq .name | tr -d '"') ]]; then
  az network public-ip create -g "$NETWORK_RESOURCE_GROUP" -n "$DNS_PIP_NAME2" -l "$AZURE_LOCATION" --allocation-method Static
fi
DNS_PIP_ID2=$(az network public-ip show -g "$NETWORK_RESOURCE_GROUP" -n "$DNS_PIP_NAME2" | jq .id | tr -d '"')
DNS_PIP_2=$(az network public-ip show -g "$NETWORK_RESOURCE_GROUP" -n "$DNS_PIP_NAME2" | jq .ipAddress | tr -d '"')


# Create NIC for dns server2
if [[ -z $(az network nic show -n $DNS_NIC_NAME2 -g $PCF_RESOURCE_GROUP | jq .name | tr -d '"') ]]; then
    echo "Creating nic for $DNS_VM_NAME2 ..."
    SUBNET_ID=$(az network vnet subnet show -n $INFRA_SUBNET_NAME -g $NETWORK_RESOURCE_GROUP --vnet-name $VNET_NAME | jq .id | tr -d '"')
    az network nic create \
        --name "$DNS_NIC_NAME2" \
        --resource-group "$PCF_RESOURCE_GROUP" \
        --location "$AZURE_LOCATION" \
	--subnet $SUBNET_ID \
        --private-ip-address "$DNS_PRIVATE_IP2" \
        --public-ip-address "$DNS_PIP_ID2"
	
else
    echo "Skipping nic create. Nic $DNS_NIC_NAME2 already exists."
fi

# Create dns server2

if [[ -z $(az vm show -n "$DNS_VM_NAME2" -g "$PCF_RESOURCE_GROUP"  | jq .name | tr -d '"') ]]; then
    echo "Creating vm $DNS_VM_NAME2 ..."
    az vm create --resource-group "$PCF_RESOURCE_GROUP" \
        --name "$DNS_VM_NAME2" \
	--location "$AZURE_LOCATION" \
	--nics "$DNS_NIC_NAME2" \
	--image "$DNS_IMAGE_URN" \
	--admin-username "$DNS_VM_USER" \
	--storage-account "$BOSH_STORAGE_NAME" \
	--size Standard_DS2_v2 \
	--ssh-key-value "$DNS_PUBLIC_KEY_FILE" \
	--use-unmanaged-disk
else
    echo "Skipping vm create. vm $DNS_VM_NAME2 already exists."
fi

echo "Configuring dnsmasq in $DNS_VM_NAME2, NOT using jumpbox ...."
# Following assumes that dns servers have access to internet
#ssh -i $DNS_SERVER_PRIVATE_KEY_FILE -o StrictHostKeyChecking=no ${DNS_VM_USER}@$DNS_PRIVATE_IP1 'sudo apt-get update && sudo apt-get install -y dnsmasq && echo \"address=/$TOP_LEVEL_DOMAIN/$ALB_PIP\" | sudo tee --append /etc/dnsmasq.conf && sudo service dnsmasq restart'
#ssh -i $DNS_SERVER_PRIVATE_KEY_FILE -o StrictHostKeyChecking=no ${DNS_VM_USER}@$DNS_PRIVATE_IP2 'ho \"address=/$OPSMAN_DOMAIN/$OPSMAN_PRIVATE_IP\" | sudo tee --append /etc/dnsmasq.conf && sudo service dnsmasq restart'
ssh -i $DNS_SERVER_PRIVATE_KEY_FILE -o StrictHostKeyChecking=no ${DNS_VM_USER}@$DNS_PIP_2 "sudo apt-get update && sudo apt-get install -y dnsmasq && echo \"address=/$TOP_LEVEL_DOMAIN/$ALB_PIP\" | sudo tee --append /etc/dnsmasq.conf && sudo service dnsmasq restart"
ssh -i $DNS_SERVER_PRIVATE_KEY_FILE -o StrictHostKeyChecking=no ${DNS_VM_USER}@$DNS_PIP_2 "sudo echo \"address=/$OPSMAN_DOMAIN/$OPSMAN_PRIVATE_IP\" | sudo tee --append /etc/dnsmasq.conf && sudo service dnsmasq restart"
ssh -i $DNS_SERVER_PRIVATE_KEY_FILE -o StrictHostKeyChecking=no ${DNS_VM_USER}@$DNS_PIP_2 "sudo echo \"address=/$DNS_SYSTEM_DOMAIN/$ALB_PIP\" | sudo tee --append /etc/dnsmasq.conf && sudo service dnsmasq restart"
ssh -i $DNS_SERVER_PRIVATE_KEY_FILE -o StrictHostKeyChecking=no ${DNS_VM_USER}@$DNS_PIP_2 "sudo echo \"address=/$DNS_APPS_DOMAIN/$ALB_PIP\" | sudo tee --append /etc/dnsmasq.conf && sudo service dnsmasq restart"

# update vnet with dns servers

az network vnet update -n $VNET_NAME -g $NETWORK_RESOURCE_GROUP --set dhcpOptions.dnsServers="[\"$DNS_PRIVATE_IP1\",\"$DNS_PRIVATE_IP2\",\"$NETWORKS_DNS\"]"
