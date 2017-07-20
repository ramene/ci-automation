#!/bin/bash
set -ex

CWD=$(pwd)

mv /terraform /usr/local/bin

cd pcfawsops-terraform-state-get
# get From terrastate
while read -r line
do
  `echo "$line" | awk '{print "export "$1"="$3}'`
done < <(terraform output)

export AWS_ACCESS_KEY_ID=`terraform state show aws_iam_access_key.pcf_iam_user_access_key | grep ^id | awk '{print $3}'`
export AWS_SECRET_ACCESS_KEY_ID=`terraform state show aws_iam_access_key.pcf_iam_user_access_key | grep ^secret | awk '{print $3}'`
export AWS_SECRET_ACCESS_KEY_ID_ESCAPED=${AWS_SECRET_ACCESS_KEY_ID//\//\\/}
export RDS_PASSWORD=`terraform state show aws_db_instance.pcf_rds | grep ^password | awk '{print $3}'`

cd $CWD
#cd pcf-automation/pcf-opsman/install-pcf/iaas_config/aws/



json_file_path="pcf-automation/pcf-opsman/install-pcf/json-opsman/${AWS_TEMPLATE_DIR}"

# AWS IaaS Config

iaas_json_template=$json_file_path/iaas-config-template.json
iaas_json_file=$json_file_path/iaas-config.json
cp $iaas_json_template $iaas_json_file
sed -i -e "s/{{aws_access_key}}/${AWS_ACCESS_KEY_ID}/g" $iaas_json_file
sed -i -e "s/{{aws_secret_key}}/${AWS_SECRET_ACCESS_KEY_ID_ESCAPED}/g" $iaas_json_file
sed -i -e "s/{{vpc_id}}/${vpc_id}/g" $iaas_json_file
sed -i -e "s/{{security_group}}/${pcf_security_group}/g" $iaas_json_file
sed -i -e "s/{{key_pair_name}}/${AWS_KEY_NAME}/g" $iaas_json_file
#sed -i -e "s#{{ssh_private_key}}#${PK_STRING}#g" $iaas_json_file
sed -i -e "s/{{aws_region}}/${AWS_REGION}/g" $iaas_json_file

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
export S3_ESCAPED=${S3_ENDPOINT//\//\\/}
sed -i -e "s/{{s3_endpoint}}/${S3_ESCAPED}/g" $director_json_file
sed -i -e "s/{{s3_bucket_name}}/${s3_pcf_bosh}/g" $director_json_file
sed -i -e "s/{{aws_access_key}}/${AWS_ACCESS_KEY_ID}/g" $director_json_file
sed -i -e "s/{{aws_secret_key}}/${AWS_SECRET_ACCESS_KEY_ID_ESCAPED}/g" $director_json_file
sed -i -e "s/{{database_type}}/${DATABASE_TYPE}/g" $director_json_file
sed -i -e "s/{{db_host}}/${db_host}/g" $director_json_file
sed -i -e "s/{{db_port}}/${db_port}/g" $director_json_file
sed -i -e "s/{{db_user}}/${db_username}/g" $director_json_file
sed -i -e "s/{{db_password}}/${RDS_PASSWORD}/g" $director_json_file
sed -i -e "s/{{database_name}}/${db_database}/g" $director_json_file

# AZ config

az_json_template=$json_file_path/az-config-template.json
az_json_file=$json_file_path/az-config.json
cp $az_json_template $az_json_file
sed -i -e "s/{{AZ1}}/${az1}/g" $az_json_file
sed -i -e "s/{{AZ2}}/${az2}/g" $az_json_file
sed -i -e "s/{{AZ3}}/${az3}/g" $az_json_file

# Network Config
network_json_template=$json_file_path/network-config-template.json
network_json_file=$json_file_path/network-config.json
cp $network_json_template $network_json_file
sed -i -e "s/{{ICMP_ENABLED}}/${ICMP_ENABLED}/g" $network_json_file
sed -i -e "s/{{NETWORK1}}/${NETWORK1}/g" $network_json_file
sed -i -e "s/{{NETWORK1_IS_SERVICE}}/${NETWORK1_IS_SERVICE}/g" $network_json_file
sed -i -e "s/{{NETWORK2}}/${NETWORK2}/g" $network_json_file
sed -i -e "s/{{NETWORK2_IS_SERVICE}}/${NETWORK2_IS_SERVICE}/g" $network_json_file
sed -i -e "s/{{deployment_subnet_1}}/${ert_subnet_id_az1}/g" $network_json_file
sed -i -e "s/{{deployment_subnet_2}}/${ert_subnet_id_az2}/g" $network_json_file
sed -i -e "s/{{deployment_subnet_3}}/${ert_subnet_id_az3}/g" $network_json_file
sed -i -e "s/{{services_subnet_1}}/${services_subnet_id_az1}/g" $network_json_file
sed -i -e "s/{{services_subnet_2}}/${services_subnet_id_az2}/g" $network_json_file
sed -i -e "s/{{services_subnet_3}}/${services_subnet_id_az3}/g" $network_json_file
sed -i -e "s/{{aws_az1}}/${az1}/g" $network_json_file
sed -i -e "s/{{aws_az2}}/${az2}/g" $network_json_file
sed -i -e "s/{{aws_az3}}/${az3}/g" $network_json_file
sed -i -e "s/{{ip_prefix}}/${IP_PREFIX}/g" $network_json_file



# Network Config
network_assignment_json_template=$json_file_path/network_assignment_json_template.json
network_assignment_json_file=$json_file_path/network-assignment-config.json
cp $network_assignment_json_template $network_assignment_json_file
sed -i -e "s/{{SINGLETON_AVAILABILITY_ZONE}}/${SINGLETON_AVAILABILITY_ZONE}/g" $network_assignment_json_file
sed -i -e "s/{{SINGLETON_AVAILABILITY_NETWORK}}/${SINGLETON_AVAILABILITY_NETWORK}/g" $network_assignment_json_file

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
	-ssh-key "$PRIVATE_KEY" \
	-d "$(cat ${director_json_file})" \
	-a "$(cat ${az_json_file})" \
	-n "$(cat ${network_json_file})" \
	-na "$(cat ${network_assignment_json_file})" 

#om-alpine -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" apply-changes

#om-linux -t https://opsman.$ERT_DOMAIN -k \
#       -u "$OPSMAN_USER" \
#       -p "$OPSMAN_PASSWORD" \
#  apply-changes
