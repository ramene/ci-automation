#!/bin/bash
set -ex

cp /om-alpine /usr/local/bin
cp /terraform /usr/local/bin
cp /pcf-metadata metadata

sed -i -e "s#{{opsman_url}}#https://${OPSMAN_HOST}#g" metadata
sed -i -e "s/{{opsman_username}}/${OPSMAN_USER}/g" metadata
sed -i -e "s/{{opsman_password}}/${OPSMAN_PASSWORD}/g" metadata

CWD=$(pwd)

cp $CWD/pcfawsops-terraform-state-get/terraform.tfstate .
while read -r line
do
    `echo "$line" | awk '{print "export "$1"="$3}'`
done < <(terraform output)
cd $CWD

# Set JSON Config Template and inster Concourse Parameter Values
json_file_path="pcf-automation/pcf-opsman/install-pcf/product_configs/splunk"
json_file_template="${json_file_path}/${SPLUNK_TEMPLATE}"
json_file="${json_file_path}/splunk.json"
cp ${json_file_template} ${json_file}

sed -i -e "s#{{add_app_info}}#${ADD_APP_INFO}#g" ${json_file}
sed -i -e "s#{{cf_api_endpoint}}#${CF_API_ENDPOINT}#g" ${json_file}
sed -i -e "s#{{cf_api_user}}#${CF_API_USER}#g" ${json_file}
sed -i -e "s#{{cf_api_password}}#${CF_API_PASSWORD}#g" ${json_file}
sed -i -e "s#{{firehose_subscription_id}}#${FIREHOSE_SUBSCRIPTION_ID}#g" ${json_file}
sed -i -e "s#{{splunk_token}}#${SPLUNK_TOKEN}#g" ${json_file}
sed -i -e "s#{{splunk_index}}#${SPLUNK_INDEX}#g" ${json_file}
sed -i -e "s#{{splunk_server}}#${SPLUNK_SERVER}#g" ${json_file}
sed -i -e "s#{{splunk_ssl}}#${SPLUNK_SSL}#g" ${json_file}
sed -i -e "s#{{splunk_ssl_password}}#${SPLUNK_SSL_PASSWORD}#g" ${json_file}
sed -i -e "s#{{splunk_ssl_common_name}}#${SPLUNK_SSL_COMMON_NAME}#g" ${json_file}
sed -i -e "/{{splunk_ssl_cert}}/d" ${json_file}
echo "splunk_ssl_cert: |" >> ${json_file}
splunk_ssl_cert=$(sed 's#^#  #g' <<< "$SPLUNK_SSL_CERT")
echo "$splunk_ssl_cert" >> ${json_file}

sed -i -e "/{{splunk_ssl_root_ca}}/d" ${json_file}
echo "splunk_ssl_root_ca: |" >> ${json_file}
splunk_ssl_root_ca=$(sed 's#^#  #g' <<< "$SPLUNK_SSL_ROOT_CA")
echo "$splunk_ssl_root_ca" >> ${json_file}


pcf configure splunk-ecs ${json_file}

json_file_template="${json_file_path}/${SPLUNK_JOBS_TEMPLATE}"
json_file="${json_file_path}/splunk-jobs.json"
cp ${json_file_template} ${json_file}

for i in $(seq 1 $AZ_COUNT); do
  azString="az"$i
  sed -i -e "s/{{$azString}}/${!azString}/g" ${json_file}
done
sed -i -e "s#{{SPLUNK_NETWORK}}#${SPLUNK_NETWORK}#g" ${json_file}

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
echo "Deploying Splunk Tile @ https://$OPSMAN_HOST ..."
echo "=============================================================================================="
# Get cf Product Guid
guid_splunk=$(fn_om_linux_curl "GET" "/api/v0/staged/products" | jq '.[] | select(.type == "splunk-ecs") | .guid' | tr -d '"' | grep "splunk-ecs-.*")

echo "=============================================================================================="
echo "Found Splunk Tile  Deployment with guid of ${guid_splunk}"
echo "=============================================================================================="

# Set Networks & AZs
echo "=============================================================================================="
echo "Setting Availability Zones & Networks for: ${guid_splunk}"
echo "=============================================================================================="


json_net_and_az=$(cat ${json_file} | jq .networks_and_azs)
fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_splunk}/networks_and_azs" "${json_net_and_az}"

# Set RabbitMQ Properties - properties are set using pcf utility
#echo "=============================================================================================="
#echo "Setting Properties for: ${guid_splunk}"
#echo "=============================================================================================="

#json_properties=$(cat ${json_file} | jq .properties)
#fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_splunk}/properties" "${json_properties}"

# Set Resource Configs
echo "=============================================================================================="
echo "Setting Resource Job Properties for: ${guid_splunk}"
echo "=============================================================================================="
json_jobs_configs=$(cat ${json_file} | jq .jobs )
json_job_guids=$(fn_om_linux_curl "GET" "/api/v0/staged/products/${guid_splunk}/jobs" | jq .)

for job in $(echo ${json_jobs_configs} | jq . | jq 'keys' | jq .[] | tr -d '"'); do
  json_job_guid_cmd="echo \${json_job_guids} | jq '.jobs[] | select(.name == \"${job}\") | .guid' | tr -d '\"'"
  json_job_guid=$(eval ${json_job_guid_cmd})
  json_job_config_cmd="echo \${json_jobs_configs} | jq '.[\"${job}\"]' "
  json_job_config=$(eval ${json_job_config_cmd})
  echo "---------------------------------------------------------------------------------------------"
  echo "Setting ${json_job_guid} with --data=${json_job_config}..."
  fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_splunk}/jobs/${json_job_guid}/resource_config" "${json_job_config}"
done


# Apply Changes in Opsman
#echo "=============================================================================================="
#echo "Applying OpsMan Changes to Deploy: ${guid_splunk}"
#echo "=============================================================================================="
#om-alpine --target https://$OPSMAN_HOST -k --username "$OPSMAN_USER" --password "$OPSMAN_PASSWORD" apply-changes
