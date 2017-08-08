#!/bin/bash
set -e

cp /om-alpine /usr/local/bin

CWD=$(pwd)

CMD=om-alpine

# Set JSON Config Template and inster Concourse Parameter Values
json_file_path="pcf-automation/pcf-opsman/install-pcf/product_configs/ert"
json_file_template="${json_file_path}/${ERT_TEMPLATE}"
json_file="${json_file_path}/ert.json"

cp ${json_file_template} ${json_file}

# Test if the ssl cert var from concourse is set to 'genrate'.  If so, script will gen a self signed, otherwise will assume its a cert
if [[ ${ERT_SSL_CERT} == "generate" ]]; then
  echo "=============================================================================================="
  echo "Generating Self Signed Certs for system.${ERT_DOMAIN} & cfapps.${ERT_DOMAIN} ..."
  echo "=============================================================================================="
  pcf-automation/pcf-opsman/install-pcf/scripts/ssl/gen_ssl_certs.sh "system.${ERT_DOMAIN}" "apps.${ERT_DOMAIN}"
  ERT_SSL_CERT=$(cat system.${ERT_DOMAIN}.crt)
  ERT_SSL_KEY=$(cat system.${ERT_DOMAIN}.key)
fi

my_pcf_ert_ssl_cert=$(echo ${ERT_SSL_CERT} | sed 's/\s\+/\\\\r\\\\n/g' | sed 's/\\\\r\\\\nCERTIFICATE/ CERTIFICATE/g')
my_pcf_ert_ssl_key=$(echo ${ERT_SSL_KEY} | sed 's/\s\+/\\\\r\\\\n/g' | sed 's/\\\\r\\\\nRSA\\\\r\\\\nPRIVATE\\\\r\\\\nKEY/ RSA PRIVATE KEY/g')

sed -i -e "s|{{pcf_ert_ssl_cert}}|${my_pcf_ert_ssl_cert}|g" ${json_file}
sed -i -e "s|{{pcf_ert_ssl_key}}|${my_pcf_ert_ssl_key}|g" ${json_file}
sed -i -e "s/{{pcf_ert_domain}}/${ERT_DOMAIN}/g" ${json_file}
sed -i -e "s/{{ERT_NETWORK}}/${ERT_NETWORK}/g" ${json_file}
sed -i -e "s/{{ERT_SINGLETON_AZ}}/${ERT_SINGLETON_AZ}/g" ${json_file}
sed -i -e "s/{{HA_PROXY_IPS}}/${HA_PROXY_IPS}/g" ${json_file}
sed -i -e "s/{{MYSQL_MONITOR_EMAIL}}/${MYSQL_MONITOR_EMAIL}/g" ${json_file}
for i in $(seq 1 $AZ_COUNT); do 
  azString="AZ"$i
  sed -i -e "s/{{$azString}}/${!azString}/g" ${json_file}
done

if [[ ! -f ${json_file} ]]; then
  echo "Error: cant find file=[${json_file}]"
  exit 1
fi


DOMAINS=$(cat <<-EOF
  {"domains": ["*.$ERT_DOMAIN", "*.$ERT_DOMAIN", "*.login.$ERT_DOMAIN", "*.uaa.$ERT_DOMAIN"] }
EOF
)

CERTIFICATES=`$CMD -t https://$OPSMAN_HOST -u $OPSMAN_USER -p $OPSMAN_PASSWORD -k curl -p "/api/v0/certificates/generate" -x POST -d "$DOMAINS"`

export SSL_CERT=`echo $CERTIFICATES | jq '.certificate' | tr -d '"'`
export SSL_PRIVATE_KEY=`echo $CERTIFICATES | jq '.key' | tr -d '"'`

echo "Using self signed certificates generated using Ops Manager..."

echo "\n$SSL_CERT\n"
echo "\n$SSL_PRIVATE_KEY\n"

echo "\n$ERT_SSL_CERT\n\n\n\n\n"

echo "\n$SVCPROVIDER_SSL_CERT\n"
echo "\n$SVCPROVIDER_SSL_KEY\n"

if [[ "$authentication_mode" == "ldap" ]]; then
echo "Configuring LDAP Authentication in ERT..."
CF_AUTH_PROPERTIES=$(cat <<-EOF
{
  ".properties.uaa": {
    "value": "ldap"
  },
  ".uaa.service_provider_key_credentials": {
    "value": {
      "cert_pem": "$SSL_CERT",
      "private_key_pem": "$SSL_PRIVATE_KEY"
    }
  },
  ".properties.uaa.ldap.server_ssl_cert": {
    "value": "$ERT_SSL_CERT"
  },
  ".properties.uaa.ldap.url": {
    "value": "$LDAP_URL"
  },
  ".properties.uaa.ldap.credentials": {
    "value": {
      "identity": "$LDAP_USER",
      "password": "$LDAP_PASSWORD"
    }
  },
  ".properties.uaa.ldap.search_base": {
    "value": "$SEARCH_BASE"
  },
  ".properties.uaa.ldap.search_filter": {
    "value": "$SEARCH_FILTER"
  },
  ".properties.uaa.ldap.group_search_base": {
    "value": "$GROUP_SEARCH_BASE"
  },
  ".properties.uaa.ldap.group_search_filter": {
    "value": "$GROUP_SEARCH_FILTER"
  },
  ".properties.uaa.ldap.mail_attribute_name": {
    "value": "$MAIL_ATTR_NAME"
  },
  ".properties.uaa.ldap.first_name_attribute": {
    "value": "$FIRST_NAME_ATTR"
  },
  ".properties.uaa.ldap.last_name_attribute": {
    "value": "$LAST_NAME_ATTR"
  }
}
EOF
)

fi
$CMD -t https://$OPSMAN_HOST -u $OPSMAN_USER -p $OPSMAN_PASSWORD -k configure-product -n cf -p "$CF_AUTH_PROPERTIES"


function fn_om_linux_curl {

    local curl_method=${1}
    local curl_path=${2}
    local curl_data=${3}

     curl_cmd="om-alpine --target https://$OPSMAN_HOST -k \
            --username \"$OPSMAN_USER\" \
            --password \"$OPSMAN_PASSWORD\"  \
            curl \
            --request ${curl_method} \
            --path ${curl_path}"

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
echo "Deploying ERT @ https://$OPSMAN_HOST ..."
echo "=============================================================================================="
# Get cf Product Guid
guid_cf=$(fn_om_linux_curl "GET" "/api/v0/staged/products" \
            | jq '.[] | select(.type == "cf") | .guid' | tr -d '"' | grep "cf-.*")

echo "=============================================================================================="
echo "Found ERT Deployment with guid of ${guid_cf}"
echo "=============================================================================================="

# Set Networks & AZs
echo "=============================================================================================="
echo "Setting Availability Zones & Networks for: ${guid_cf}"
echo "=============================================================================================="

json_net_and_az=$(cat ${json_file} | jq .networks_and_azs)
fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_cf}/networks_and_azs" "${json_net_and_az}"

# Set ERT Properties
echo "=============================================================================================="
echo "Setting Properties for: ${guid_cf}"
echo "=============================================================================================="

json_properties=$(cat ${json_file} | jq .properties)
fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_cf}/properties" "${json_properties}"

# Set Resource Configs - for our labs all settings are default
#echo "=============================================================================================="
#echo "Setting Resource Job Properties for: ${guid_cf}"
#echo "=============================================================================================="
#json_jobs_configs=$(cat ${json_file} | jq .jobs )
#json_job_guids=$(fn_om_linux_curl "GET" "/api/v0/staged/products/${guid_cf}/jobs" | jq .)

#for job in $(echo ${json_jobs_configs} | jq . | jq 'keys' | jq .[] | tr -d '"'); do

# json_job_guid_cmd="echo \${json_job_guids} | jq '.jobs[] | select(.name == \"${job}\") | .guid' | tr -d '\"'"
# json_job_guid=$(eval ${json_job_guid_cmd})
# json_job_config_cmd="echo \${json_jobs_configs} | jq '.[\"${job}\"]' "
# json_job_config=$(eval ${json_job_config_cmd})
# echo "---------------------------------------------------------------------------------------------"
# echo "Setting ${json_job_guid} with --data=${json_job_config}..."
# fn_om_linux_curl "PUT" "/api/v0/staged/products/${guid_cf}/jobs/${json_job_guid}/resource_config" "${json_job_config}"

#done
