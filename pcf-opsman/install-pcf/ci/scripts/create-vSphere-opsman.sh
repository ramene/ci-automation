#!/bin/bash
set -e

echo "=============================================================================================="
echo "Deploying Ops Manager version $OPSMAN_VERSION ..."
echo "=============================================================================================="

#Create Opsman

echo "=============================================================================================="
echo "Executing ovf command ...."
vcenter_user=${VCENTER_USER//\\/%5c}
vcenter_user=${vcenter_user/@/%40}
vcenter_pass=${VCENTER_PASSWORD//\\/%5c}
vcenter_pass=${vcenter_pass/@/%40}

if [[ $IAAS == "vSphere" ]]; then
    ops_manager_file_name=$(ls pcf-products/*.ova)
fi

ovf_cmd="ovftool --name='pcf-vsphere-$OPSMAN_VERSION' \
        -nw=$NETWORK_NAME \
        -ds=$DATA_STORE_NAME \
        -dm=$DISK_TYPE \
        --prop:ip0=$OPSMAN_IP \
        --prop:netmask0=$OPSMAN_NETMASK \
        --prop:gateway=$OPSMAN_GATEWAY \
        --prop:DNS=$OPSMAN_DNS \
        --prop:ntp_servers=$OPSMAN_NTP \
	--prop:admin_password=$OPSMAN_VM_PASS \
	--powerOn \
        --noSSLVerify \
        --acceptAllEulas \
        --sourceType=ova \
        $ops_manager_file_name \
	vi://$VCENTER_USER:$VCENTER_PASSWORD@$VCENTER_HOST/$DATACENTER_NAME/host/$CLUSTER_NAME"
echo $ovf_cmd
eval $ovf_cmd

echo "=============================================================================================="

