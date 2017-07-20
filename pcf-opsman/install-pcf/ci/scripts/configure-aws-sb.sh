#!/bin/bash
set -ex

# No need to have separate script for different IaaS as we cannot configure job VMs

cp /om-alpine /usr/local/bin
cp /terraform /usr/local/bin

CWD=$(pwd)

cp $CWD/pcfawsops-terraform-state-get/terraform.tfstate .
while read -r line
do
    `echo "$line" | awk '{print "export "$1"="$3}'`
done < <(terraform output)

cd $CWD    

cp aws-sb-terraform-state-get/${S3_AWS_SB_TF_STATE_FILE_NAME} terraform.tfstate
export AWS_SB_ACCESS_KEY=`terraform state show aws_iam_access_key.aws_service_broker_iam_user_access_key | grep ^id | awk '{print $3}'`
export AWS_SB_SECRET_KEY=`terraform state show aws_iam_access_key.aws_service_broker_iam_user_access_key | grep ^secret | awk '{print $3}'`
export AWS_SB_RDS_HOST=`terraform state show aws_db_instance.pcf_rds | grep ^address| awk '{print $3}'`
export AWS_SB_RDS_PORT=`terraform state show aws_db_instance.pcf_rds | grep ^port | awk '{print $3}'`
export AWS_SB_RDS_USERNAME=`terraform state show aws_db_instance.pcf_rds | grep ^username | awk '{print $3}'`
export AWS_SB_RDS_PASSWORD=`terraform state show aws_db_instance.pcf_rds | grep ^password | awk '{print $3}'`
export AWS_SB_RDS_DBNAME=`terraform state show aws_db_instance.pcf_rds | grep ^name | awk '{print $3}'`


export RDS_DB_SUBNET_GROUP_NAME=`terraform state show aws_db_instance.pcf_rds |grep ^db_subnet_group_name | awk '{print $3}'`
export RDS_DB_SUBNET_SECURITY_GROUP_ID=`terraform state show aws_security_group.rds_broker_SG |grep ^id | awk '{print $3}'`



# Set JSON Config Template and inster Concourse Parameter Values
json_file_path="pcf-automation/pcf-opsman/install-pcf/product_configs/aws-service-broker"
#json_file_path="."
json_file_template="${json_file_path}/${AWS_SB_TEMPLATE}"
json_file="${json_file_path}/aws_sb.json"

cp ${json_file_template} ${json_file}

for i in $(seq 1 $AZ_COUNT); do
  azString="az"$i
  sed -i -e "s/{{$azString}}/${!azString}/g" ${json_file}
done

sed -i -e "s|{{AWS_SB_NETWORK}}|${AWS_SB_NETWORK}|g" ${json_file}
sed -i -e "s|{{AWS_SB_ACCESS_KEY}}|${AWS_SB_ACCESS_KEY}|g" ${json_file}
sed -i -e "s|{{AWS_SB_SECRET_KEY}}|${AWS_SB_SECRET_KEY}|g" ${json_file}
sed -i -e "s|{{AWS_SB_DEFAULT_REGION}}|${AWS_SB_DEFAULT_REGION}|g" ${json_file}
sed -i -e "s|{{AWS_SB_RDS_HOST}}|${AWS_SB_RDS_HOST}|g" ${json_file}
sed -i -e "s|{{AWS_SB_RDS_PORT}}|${AWS_SB_RDS_PORT}|g" ${json_file}
sed -i -e "s|{{AWS_SB_RDS_USERNAME}}|${AWS_SB_RDS_USERNAME}|g" ${json_file}
sed -i -e "s|{{AWS_SB_RDS_PASSWORD}}|${AWS_SB_RDS_PASSWORD}|g" ${json_file}
sed -i -e "s|{{AWS_SB_RDS_DBNAME}}|${AWS_SB_RDS_DBNAME}|g" ${json_file}
sed -i -e "s|{{AWS_SB_RDS_DEFAULT_REGION}}|${AWS_SB_RDS_DEFAULT_REGION}|g" ${json_file}
sed -i -e "s|{{AWS_SB_RDS_DEFAULT_AZ}}|${AWS_SB_RDS_DEFAULT_AZ}|g" ${json_file}
sed -i -e "s|{{RDS_DB_SUBNET_GROUP_NAME}}|${RDS_DB_SUBNET_GROUP_NAME}|g" ${json_file}
sed -i -e "s|{{RDS_DB_SUBNET_SECURITY_GROUP_ID}}|${RDS_DB_SUBNET_SECURITY_GROUP_ID}|g" ${json_file}
sed -i -e "s|{{AWS_SB_S3_DEFAULT_REGION}}|${AWS_SB_S3_DEFAULT_REGION}|g" ${json_file}
sed -i -e "s|{{AWS_SB_SQS_DEFAULT_REGION}}|${AWS_SB_SQS_DEFAULT_REGION}|g" ${json_file}




function fn_om_linux_curl {

    local curl_method=${1}
    local curl_path=${2}
    local curl_data=${3}

     curl_cmd="om-alpine --target https://$OPSMAN_HOST -k --username \"$OPSMAN_USER\" --password \"$OPSMAN_PASSWORD\"  \
            curl --request ${curl_method} --path ${curl_path}"

    if [[ ! -z ${curl_data} ]]; then
       curl_cmd="${curl_cmd} --data '${curl_data}'"
    fi

    echo ${curl_cmd} > /tmp/rqst_cmd.log
    exec_out=$(((eval $curl_cmd | tee /tmp/rqst_stdout.log) 3>&1 1>&2 2>&3 | tee /tmp/rqst_stderr.log) &>/dev/null)

    if [[ $(cat /tmp/rqst_stderr.log | grep "Status:" | awk '{print$2}') != "200" ]]; then
      echo "Error Call Failed ...."
      echo $(cat /tmp/rqst_stderr.log)
      exit 1
    else
      echo $(cat /tmp/rqst_stdout.log)
    fi
}



echo "=============================================================================================="
echo "Deploying AWS Service Broker @ https://$OPSMAN_HOST ..."
echo "=============================================================================================="
# Get cf Product Guid
guid_aws_sb=$(fn_om_linux_curl "GET" "/api/v0/staged/products" | jq '.[] | select(.type == "aws-services") | .guid' | tr -d '"' | grep "aws-services-.*")

echo "=============================================================================================="
echo "Found AWS Service Broker Deployment with guid of ${guid_aws_sb}"
echo "=============================================================================================="

# Set Networks & AZs
echo "=============================================================================================="
echo "Setting Availability Zones & Networks for: ${guid_aws_sb}"
echo "=============================================================================================="


json_net_and_az=$(cat ${json_file} | jq .networks_and_azs)
fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_aws_sb}/networks_and_azs" "${json_net_and_az}"

# Set ERT Properties
echo "=============================================================================================="
echo "Setting Properties for: ${guid_aws_sb}"
echo "=============================================================================================="

json_properties=$(cat ${json_file} | jq .properties)
fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_aws_sb}/properties" "${json_properties}"

# Set Resource Configs
echo "=============================================================================================="
echo "Setting Resource Job Properties for: ${guid_aws_sb}"
echo "=============================================================================================="
json_jobs_configs=$(cat ${json_file} | jq .jobs )
json_job_guids=$(fn_om_linux_curl "GET" "/api/v0/staged/products/${guid_aws_sb}/jobs" | jq .)

for job in $(echo ${json_jobs_configs} | jq . | jq 'keys' | jq .[] | tr -d '"'); do
  json_job_guid_cmd="echo \${json_job_guids} | jq '.jobs[] | select(.name == \"${job}\") | .guid' | tr -d '\"'"
  json_job_guid=$(eval ${json_job_guid_cmd})
  json_job_config_cmd="echo \${json_jobs_configs} | jq '.[\"${job}\"]' "
  json_job_config=$(eval ${json_job_config_cmd})
  echo "---------------------------------------------------------------------------------------------"
  echo "Setting ${json_job_guid} with --data=${json_job_config}..."
  fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_aws_sb}/jobs/${json_job_guid}/resource_config" "${json_job_config}"
done


# Apply Changes in Opsman
#echo "=============================================================================================="
#echo "Applying OpsMan Changes to Deploy: ${guid_aws_sb}"
#echo "=============================================================================================="
#om-alpine --target https://$OPSMAN_HOST -k --username "$OPSMAN_USER" --password "$OPSMAN_PASSWORD" apply-changes
