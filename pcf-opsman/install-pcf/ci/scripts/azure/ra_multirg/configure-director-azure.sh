#!/bin/bash
set -ex

CWD=$(pwd)

# for rsamban/pcf-om (alpine image)
cp /om-alpine /usr/local/bin/om

chmod +x /usr/local/bin/om


# if first argument is passed, source it - used in jenkins builds
if [[ ! -z $1 ]]; then
  source $1
fi


if [[ -z $ORG ]]; then echo "Please set ORG"; exit 1; fi
if [[ -z $OPSMAN_TEMPLATE_DIR ]]; then echo "Please set OPSMAN_TEMPLATE_DIR"; exit 1; fi
if [[ -z $AZURE_SP_CI_USER ]]; then echo "Please set AZURE_SP_CI_USER"; exit 1; fi
if [[ -z $AZURE_SP_CI_PASSWORD ]]; then echo "Please set AZURE_SP_CI_PASSWORD"; exit 1; fi
if [[ -z $OPSMAN_HOST ]]; then echo "Please set OPSMAN_HOST"; exit 1; fi
if [[ -z $OPSMAN_USER ]]; then echo "Please set OPSMAN_USER"; exit 1; fi
if [[ -z $OPSMAN_PASSWORD ]]; then echo "Please set OPSMAN_PASSWORD"; exit 1; fi

if [[ -z $SUBSCRIPTION_ID ]]; then echo "Please set SUBSCRIPTION_ID"; exit 1; fi
if [[ -z $TENANT_ID ]]; then echo "Please set TENANT_ID"; exit 1; fi
if [[ -z $SERVICE_PRINCIPAL_NAME ]]; then echo "Please set SERVICE_PRINCIPAL_NAME"; exit 1; fi
if [[ -z $CLIENT_SECRET ]]; then echo "Please set CLIENT_SECRET"; exit 1; fi
if [[ -z $PCF_RESOURCE_GROUP ]]; then echo "Please set PCF_RESOURCE_GROUP"; exit 1; fi
if [[ -z $BOSH_STORAGE_NAME ]]; then echo "Please set BOSH_STORAGE_NAME"; exit 1; fi
if [[ -z $DEPLOYMENT_STORAGE_NAME ]]; then echo "Please set DEPLOYMENT_STORAGE_NAME"; exit 1; fi
if [[ -z $PCF_NSG ]]; then echo "Please set PCF_NSG"; exit 1; fi
if [[ -z $BOSH_PUBLIC_KEY ]]; then echo "Please set BOSH_PUBLIC_KEY"; exit 1; fi
if [[ -z $BOSH_PRIVATE_KEY ]]; then echo "Please set BOSH_PRIVATE_KEY"; exit 1; fi


if [[ -z $NETWORK_RESOURCE_GROUP ]]; then echo "Please set NETWORK_RESOURCE_GROUP"; exit 1; fi
if [[ -z $PCF_NETWORKS_DNS ]]; then echo "Please set PCF_NETWORKS_DNS"; exit 1; fi
if [[ -z $VNET_NAME ]]; then echo "Please set VNET_NAME"; exit 1; fi
if [[ -z $INFRA_SUBNET_NAME ]]; then echo "Please set INFRA_SUBNET_NAME"; exit 1; fi
if [[ -z $INFRA_NETWORK_CIDR ]]; then echo "Please set INFRA_NETWORK_CIDR"; exit 1; fi
if [[ -z $INFRA_NETWORK_RESERVED ]]; then echo "Please set INFRA_NETWORK_RESERVED"; exit 1; fi
if [[ -z $INFRA_NETWORK_GW ]]; then echo "Please set INFRA_NETWORK_GW"; exit 1; fi
if [[ -z $PCF_SUBNET_NAME ]]; then echo "Please set PCF_SUBNET_NAME"; exit 1; fi
if [[ -z $PCF_NETWORK_CIDR ]]; then echo "Please set PCF_NETWORK_CIDR"; exit 1; fi
if [[ -z $PCF_NETWORK_RESERVED ]]; then echo "Please set PCF_NETWORK_RESERVED"; exit 1; fi
if [[ -z $PCF_NETWORK_GW ]]; then echo "Please set PCF_NETWORK_GW"; exit 1; fi
if [[ -z $SERVICES_SUBNET_NAME ]]; then echo "Please set SERVICES_SUBNET_NAME"; exit 1; fi
if [[ -z $SERVICES_NETWORK_CIDR ]]; then echo "Please set SERVICES_NETWORK_CIDR"; exit 1; fi
if [[ -z $SERVICES_NETWORK_RESERVED ]]; then echo "Please set SERVICES_NETWORK_RESERVED"; exit 1; fi
if [[ -z $SERVICES_NETWORK_GW ]]; then echo "Please set SERVICES_NETWORK_GW"; exit 1; fi
if [[ -z $DYNAMIC_SERVICES_SUBNET_NAME ]]; then echo "Please set DYNAMIC_SERVICES_SUBNET_NAME"; exit 1; fi
if [[ -z $DYNAMIC_SERVICES_NETWORK_CIDR ]]; then echo "Please set DYNAMIC_SERVICES_NETWORK_CIDR"; exit 1; fi
if [[ -z $DYNAMIC_SERVICES_NETWORK_RESERVED ]]; then echo "Please set DYNAMIC_SERVICES_NETWORK_RESERVED"; exit 1; fi
if [[ -z $DYNAMIC_SERVICES_NETWORK_GW ]]; then echo "Please set DYNAMIC_SERVICES_NETWORK_GW"; exit 1; fi

if [[ -z $NTP_SERVERS ]]; then echo "Please set NTP_SERVERS"; exit 1; fi

if [[ -z $INTERNET_CONNECTED ]]; then echo "Please set INTERNET_CONNECTED"; exit 1; fi


IAAS_CONFIG="$(source $OPSMAN_TEMPLATE_DIR/iaas_config.json)"
echo "===========================================Azure Config==================================================="
echo "IAAS_CONFIG = $IAAS_CONFIG"
echo "=============================================================================================="

DIRECTOR_CONFIG="$(source $OPSMAN_TEMPLATE_DIR/director-config.json)"
echo "===========================================Director Config==================================================="
echo $DIRECTOR_CONFIG
echo "=============================================================================================="

NETWORK_CONFIG="$(source $OPSMAN_TEMPLATE_DIR/network-config.json)"
echo "===========================================Network Config==================================================="
echo $NETWORK_CONFIG
echo "=============================================================================================="

NETWORK_ASSIGNMENT="$(source $OPSMAN_TEMPLATE_DIR/network-assignment.json)"
echo "===========================================Network Assignment Config==================================================="
echo $NETWORK_ASSIGNMENT
echo "=============================================================================================="

json_jobs_configs=$(source $OPSMAN_TEMPLATE_DIR/jobs_config.json)
echo "===========================================Resource Config==================================================="
echo $json_jobs_configs
echo "=============================================================================================="

echo "=============================================================================================="
echo "Configuring Ops Manager Director ..."
echo "=============================================================================================="
om -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" configure-bosh \
    -i "$IAAS_CONFIG" \
    -d "$DIRECTOR_CONFIG" \
    -n "$NETWORK_CONFIG" \
    -na "$NETWORK_ASSIGNMENT"
guid_bosh=$(om -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" curl -x GET -p "/api/v0/staged/products" | jq '.[] | select(.type == "p-bosh") | .guid' | tr -d '"' | grep "p-bosh-.*")
json_job_guids=$(om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD curl -x GET -p /api/v0/staged/products/${guid_bosh}/jobs | jq .)
for job in $(echo ${json_jobs_configs} | jq . | jq 'keys' | jq .[] | tr -d '"'); do
  json_job_guid_cmd="echo \${json_job_guids} | jq '.jobs[] | select(.name == \"${job}\") | .guid' | tr -d '\"'"
  json_job_guid=$(eval ${json_job_guid_cmd})
  json_job_config_cmd="echo \${json_jobs_configs} | jq '.[\"${job}\"]' "
  json_job_config=$(eval ${json_job_config_cmd})
  echo "Configuring $job ---------------------------------------------------------------------------------------------"
  echo "Setting ${json_job_guid} with --data=${json_job_config}"
  echo "/api/v0/staged/products/${guidl}/jobs/${json_job_guid}/resource_config"
  echo "om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD curl -x PUT -p /api/v0/staged/products/${guid_bosh}/jobs/${json_job_guid}/resource_config -d \"${json_job_config}\""
  om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD curl -x PUT -p /api/v0/staged/products/${guid_bosh}/jobs/${json_job_guid}/resource_config -d "${json_job_config}"
done


echo "=============================================================================================="
echo "Configuring Ops Manager Director. Done. "
echo "=============================================================================================="







