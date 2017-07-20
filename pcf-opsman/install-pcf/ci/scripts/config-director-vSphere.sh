#!/bin/bash
set -ex

CWD=$(pwd)


cd $CWD
json_file_path="pcf-automation/pcf-opsman/install-pcf/json-opsman/${VSPHERE_TEMPLATE_DIR}"

# vSphere Config
iaas_json_template=$json_file_path/iaas-config-template.json
iaas_json_file=$json_file_path/iaas-config.json
cp $iaas_json_template $iaas_json_file
sed -i -e "s/{{vcenter_host}}/${VCENTER_HOST}/g" $iaas_json_file
sed -i -e "s/{{vcenter_username}}/${VCENTER_USER}/g" $iaas_json_file
sed -i -e "s/{{vcenter_password}}/${VCENTER_PASSWORD}/g" $iaas_json_file
sed -i -e "s/{{datacenter}}/${DATACENTER_NAME}/g" $iaas_json_file
sed -i -e "s/{{disk_type}}/${DISK_TYPE}/g" $iaas_json_file
sed -i -e "s/{{ephemeral_datastores_string}}/${DATA_STORE_NAME}/g" $iaas_json_file
sed -i -e "s/{{persistent_datastores_string}}/${DATA_STORE_NAME}/g" $iaas_json_file
sed -i -e "s/{{bosh_vm_folder}}/${VM_FOLER}/g" $iaas_json_file
sed -i -e "s/{{bosh_template_folder}}/${TEMPLATE_FOLDER}/g" $iaas_json_file
sed -i -e "s/{{bosh_disk_path}}/${DISK_PATH_FOLDER}/g" $iaas_json_file

#Director Config
director_json_template=$json_file_path/director-config-template.json
director_json_file=$json_file_path/director-config.json
cp $director_json_template $director_json_file
sed -i -e "s/{{ntp_servers_string}}/${NTP_SERVERS_STRING}/g" $director_json_file
sed -i -e "s/{{metrics_ip}}/${METRICS_IP}/g" $director_json_file
sed -i -e "s/{{resurrector_enabled}}/${RESURRECTOR_ENABLED}/g" $director_json_file
sed -i -e "s/{{post_deploy_enabled}}/${POST_DEPLOY_ENABLED}/g" $director_json_file
sed -i -e "s/{{bosh_recreate_on_next_deploy}}/${BOSH_RECREATE_ON_NEXT_DEPLOY}/g" $director_json_file
sed -i -e "s/{{retry_bosh_deploys}}/${RETRY_BOSH_DEPLOYS}/g" $director_json_file
sed -i -e "s/{{blobstore_type}}/${BLOBSTORE_TYPE}/g" $director_json_file
sed -i -e "s/{{database_type}}/${DATABASE_TYPE}/g" $director_json_file

# AZ config

az_json_template=$json_file_path/az-config-template-${AZ_COUNT}.json
az_json_file=$json_file_path/az-config.json
cp $az_json_template $az_json_file

for i in $(seq 1 $AZ_COUNT); do 
  azString="AZ"$i
  clusterString="CLUSTER"$i
  resourcePoolString="RESOURCE_POOL"$i
  sed -i -e "s/{{$azString}}/${!azString}/g" $az_json_file
  sed -i -e "s/{{$clusterString}}/${!clusterString}/g" $az_json_file
  sed -i -e "s/{{$resourcePoolString}}/${!resourcePoolString}/g" $az_json_file
done



# Network Config
#network_json_template=$json_file_path/network-config-template-${SUBNET_COUNT}.json
network_json_template=$json_file_path/$NETWORK_CONFIG_TEMPLATE
network_json_file=$json_file_path/network-config.json
cp $network_json_template $network_json_file
sed -i -e "s/{{ICMP_ENABLED}}/${ICMP_ENABLED}/g" $network_json_file
# for NETWORK1
#sed -i -e "s/{{NETWORK1}}/${NETWORK1}/g" $network_json_file
#sed -i -e "s/{{NETWORK1_IS_SERVICE}}/${NETWORK1_IS_SERVICE}/g" $network_json_file
#sed -i -e "s/{{VSPHERE_NETWORK1}}/${VSPHERE_NETWORK1}/g" $network_json_file
#for i in $(seq 1 $SUBNET_COUNT); do 
#  cidrString="NETWORK1_CIDR"$i
#  reservedString="NETWORK1_RESERVED"$i
#  dnsString="NETWORK1_DNS"$i
#  gatewayString="NETWORK1_GATEWAY"$i
#  sed -i -e "s#{{$cidrString}}#${!cidrString}#g" $network_json_file
#  sed -i -e "s/{{$reservedString}}/${!reservedString}/g" $network_json_file
#  sed -i -e "s/{{$dnsString}}/${!dnsString}/g" $network_json_file
#  sed -i -e "s/{{$gatewayString}}/${!gatewayString}/g" $network_json_file
#done
# for NETWORK2
#sed -i -e "s/{{NETWORK2}}/${NETWORK2}/g" $network_json_file
#sed -i -e "s/{{NETWORK2_IS_SERVICE}}/${NETWORK2_IS_SERVICE}/g" $network_json_file
#sed -i -e "s/{{VSPHERE_NETWORK2}}/${VSPHERE_NETWORK2}/g" $network_json_file

#for i in $(seq 1 $SUBNET_COUNT); do 
# cidrString="NETWORK2_CIDR"$i
# reservedString="NETWORK2_RESERVED"$i
# dnsString="NETWORK2_DNS"$i
# gatewayString="NETWORK2_GATEWAY"$i
# sed -i -e "s#{{$cidrString}}#${!cidrString}#g" $network_json_file
# sed -i -e "s/{{$reservedString}}/${!reservedString}/g" $network_json_file
# sed -i -e "s/{{$dnsString}}/${!dnsString}/g" $network_json_file
# sed -i -e "s/{{$gatewayString}}/${!gatewayString}/g" $network_json_file
#done
for i in $(seq 1 $AZ_COUNT); do 
  azString="AZ"$i
  sed -i -e "s/{{$azString}}/${!azString}/g" $network_json_file
done

for i in $(seq 1 $NETWORK_COUNT); do
  networkString="NETWORK"$i
  networkIsServiceString="NETWORK"$i"_IS_SERVICE"
  sed -i -e "s/{{$networkString}}/${!networkString}/g" $network_json_file
  sed -i -e "s/{{$networkIsServiceString}}/${!networkIsServiceString}/g" $network_json_file

  for j in $(seq 1 $SUBNET_COUNT); do
    vSphereNetworkString="VSPHERE_NETWORK"$i$j
    cidrString="NETWORK"$i"_CIDR"$j
    reservedString="NETWORK"$i"_RESERVED"$j
    dnsString="NETWORK"$i"_DNS"$j
    gatewayString="NETWORK"$i"_GATEWAY"$j
    sed -i -e "s#{{$vSphereNetworkString}}#${!vSphereNetworkString}#g" $network_json_file
    sed -i -e "s#{{$cidrString}}#${!cidrString}#g" $network_json_file
    sed -i -e "s/{{$reservedString}}/${!reservedString}/g" $network_json_file
    sed -i -e "s/{{$dnsString}}/${!dnsString}/g" $network_json_file
    sed -i -e "s/{{$gatewayString}}/${!gatewayString}/g" $network_json_file

  done
done

# Network Config
network_assignment_json_template=$json_file_path/network_assignment_json_template.json
network_assignment_json_file=$json_file_path/network-assignment-config.json
cp $network_assignment_json_template $network_assignment_json_file
sed -i -e "s/{{SINGLETON_AVAILABILITY_ZONE}}/${SINGLETON_AVAILABILITY_ZONE}/g" $network_assignment_json_file
sed -i -e "s/{{NETWORK}}/${SINGLETON_NETWORK}/g" $network_assignment_json_file

# Set JSON Config Template and inster Concourse Parameter Values

echo "=============================================================================================="
echo "Deploying Director @ https://$OPSMAN_HOST ..."
cat $iaas_json_file
echo "=============================================================================================="
cat $director_json_file
echo "=============================================================================================="
cat $az_json_file
echo "=============================================================================================="
cat $network_json_file
echo "=============================================================================================="

#sudo cp tool-om-beta/om-linux /usr/local/bin
#sudo chmod 755 /usr/local/bin/om-linux

#om-linux -t https://opsman.$ERT_DOMAIN -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" -k \
#  aws -a $AWS_ACCESS_KEY_ID \
#  -s $AWS_SECRET_ACCESS_KEY \
#  -d $RDS_PASSWORD \
#  -p "$PEM" -c "$(cat ${json_file})"

cp /om-alpine /usr/local/bin
chmod 755 /usr/local/bin/om-alpine

om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" configure-bosh \
	-i "$(cat ${iaas_json_file})" \
	-d "$(cat ${director_json_file})" \
	-a "$(cat ${az_json_file})" \
	-n "$(cat ${network_json_file})" \
	-na "$(cat ${network_assignment_json_file})" 

#om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" apply-changes

#om-linux -t https://opsman.$ERT_DOMAIN -k \
#       -u "$OPSMAN_USER" \
#       -p "$OPSMAN_PASSWORD" \
#  apply-changes
