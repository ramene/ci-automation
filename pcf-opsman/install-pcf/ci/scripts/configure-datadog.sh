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
json_file_path="pcf-automation/pcf-opsman/install-pcf/product_configs/datadog"
json_file_template="${json_file_path}/${DATADOG_TEMPLATE}"
json_file="${json_file_path}/datadog.json"
cp ${json_file_template} ${json_file}

sed -i -e "s#{{boshhmforwarder_incoming_port}}#${BOSHHMFORWARDER_INCOMING_PORT}#g" ${json_file}
sed -i -e "s#{{metron_agent_deployment}}#${METRON_AGENT_DEPLOYMENT}#g" ${json_file}
sed -i -e "s#{{doppler_user}}#${DOPPLER_USER}#g" ${json_file}
sed -i -e "s#{{doppler_user_password}}#${DOPPLER_USER_PASSWORD}#g" ${json_file}
sed -i -e "s#{{insecure_ssl_skip_verify}}#${INSECURE_SSL_SKIP_VERIFY}#g" ${json_file}
sed -i -e "s#{{subscription_id}}#${SUBSCRIPTION_ID}#g" ${json_file}
sed -i -e "s#{{datadog_api_url}}#${DATADOG_API_URL}#g" ${json_file}
sed -i -e "s#{{datadog_api_key}}#${DATADOG_API_KEY}#g" ${json_file}
sed -i -e "s#{{metric_prefix}}#${METRIC_PREFIX}#g" ${json_file}

pcf configure datadog-ecs ${json_file}

json_file_template="${json_file_path}/${DATADOG_JOBS_TEMPLATE}"
json_file="${json_file_path}/datadog-jobs.json"
cp ${json_file_template} ${json_file}

for i in $(seq 1 $AZ_COUNT); do
  azString="az"$i
  sed -i -e "s/{{$azString}}/${!azString}/g" ${json_file}
done
sed -i -e "s#{{DATADOG_NETWORK}}#${DATADOG_NETWORK}#g" ${json_file}

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
echo "Deploying Datadog Tile @ https://$OPSMAN_HOST ..."
echo "=============================================================================================="
# Get cf Product Guid
guid_datadog=$(fn_om_linux_curl "GET" "/api/v0/staged/products" | jq '.[] | select(.type == "datadog-ecs") | .guid' | tr -d '"' | grep "datadog-ecs-.*")

echo "=============================================================================================="
echo "Found Splunk Tile  Deployment with guid of ${guid_datadog}"
echo "=============================================================================================="

# Set Networks & AZs
echo "=============================================================================================="
echo "Setting Availability Zones & Networks for: ${guid_datadog}"
echo "=============================================================================================="


json_net_and_az=$(cat ${json_file} | jq .networks_and_azs)
fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_datadog}/networks_and_azs" "${json_net_and_az}"

# Set RabbitMQ Properties - properties are set using pcf utility
#echo "=============================================================================================="
#echo "Setting Properties for: ${guid_datadog}"
#echo "=============================================================================================="

#json_properties=$(cat ${json_file} | jq .properties)
#fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_datadog}/properties" "${json_properties}"

# Set Resource Configs
echo "=============================================================================================="
echo "Setting Resource Job Properties for: ${guid_datadog}"
echo "=============================================================================================="
json_jobs_configs=$(cat ${json_file} | jq .jobs )
json_job_guids=$(fn_om_linux_curl "GET" "/api/v0/staged/products/${guid_datadog}/jobs" | jq .)

for job in $(echo ${json_jobs_configs} | jq . | jq 'keys' | jq .[] | tr -d '"'); do
  json_job_guid_cmd="echo \${json_job_guids} | jq '.jobs[] | select(.name == \"${job}\") | .guid' | tr -d '\"'"
  json_job_guid=$(eval ${json_job_guid_cmd})
  json_job_config_cmd="echo \${json_jobs_configs} | jq '.[\"${job}\"]' "
  json_job_config=$(eval ${json_job_config_cmd})
  echo "---------------------------------------------------------------------------------------------"
  echo "Setting ${json_job_guid} with --data=${json_job_config}..."
  fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_datadog}/jobs/${json_job_guid}/resource_config" "${json_job_config}"
done


# Apply Changes in Opsman
#echo "=============================================================================================="
#echo "Applying OpsMan Changes to Deploy: ${guid_datadog}"
#echo "=============================================================================================="
#om-alpine --target https://$OPSMAN_HOST -k --username "$OPSMAN_USER" --password "$OPSMAN_PASSWORD" apply-changes
