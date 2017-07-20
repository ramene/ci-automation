#!/bin/bash
set -e

# for rsamban/pcf-om (alpine image)
cp /om-alpine /usr/local/bin/om

# for ubuntu images
# apt-get update
# apt-get install -y wget jq
# wget https://github.com/pivotal-cf/om/releases/download/0.21.0/om-linux -O /usr/local/bin/om

chmod +x /usr/local/bin/om

CWD=$(pwd)

if [[ -z $OPSMAN_HOST ]]; then echo "Please set OPSMAN_HOST"; exit 1; fi
if [[ -z $OPSMAN_USER ]]; then echo "Please set OPSMAN_USER"; exit 1; fi
if [[ -z $OPSMAN_PASSWORD ]]; then echo "Please set OPSMAN_PASSWORD"; exit 1; fi
if [[ -z $ERT_TEMPLATE_DIR ]]; then echo "Please set ERT_TEMPLATE_DIR"; exit 1; fi
if [[ -z $ERT_NETWORK_CONFIG_JSON ]]; then echo "Please set ERT_NETWORK_CONFIG_JSON"; exit 1; fi
if [[ -z $ERT_PROPERTIES_JSON ]]; then echo "Please set ERT_PROPERTIES_JSON"; exit 1; fi
if [[ -z $ERT_JOBS_CONFIG_JSON ]]; then echo "Please set ERT_JOBS_CONFIG_JSON"; exit 1; fi
if [[ -z $ERT_SYSTEM_DOMAIN ]]; then echo "Please set ERT_SYSTEM_DOMAIN"; exit 1; fi
if [[ -z $ERT_APP_DOMAIN ]]; then echo "Please set ERT_APP_DOMAIN"; exit 1; fi
if [[ -z $ERT_SSL ]]; then echo "Please set ERT_SSL"; exit 1; fi
if [[ "$ERT_SSL" == "supplied" ]]; then
  if [[ -z $ERT_SSL_PRIVATE_KEY ]]; then echo "ERT_SSL is set to 'generate'. Please set ERT_SSL_PRIVATE_KEY"; exit 1; fi
  if [[ -z $ERT_SSL_CERT ]]; then echo "ERT_SSL is set to 'generate'. Please set ERT_SSL_CERT"; exit 1; fi
fi


INTERNET_CONNECTED=${INTERNET_CONNECTED:-false}
# instance count settings
CONSUL_SERVER_IC=${CONSUL_SERVER_IC:-1}
NATS_IC=${NATS_IC:-1}
ETCD_SERVER_IC=${ETCD_SERVER_IC:-1}
ETCD_PROXY_SERVER_IC=${ETCD_PROXY_SERVER_IC:-1}
NFS_SERVER_IC=${NFS_SERVER_IC:-1}
MYSQL_PROXY_IC=${MYSQL_PROXY_IC:-0}
MYSQL_IC=${MYSQL_IC:-0}
BACKUP_PREPARE_IC=${BACKUP_PREPARE_IC:-0}
CCDB_IC=${CCDB_IC:-0}
UAADB_IC=${UAADB_IC:-0}
UAA_IC=${UAA_IC:-1}
CLOUD_CONTROLLER_IC=${CLOUD_CONTROLLER_IC:-1}
HA_PROXY_IC=${HA_PROXY_IC:-0}
ROUTER_IC=${ROUTER_IC:-1}
MYSQL_MONITOR_IC=${MYSQL_MONITOR_IC:-1}
CLOCK_GLOBAL_IC=${CLOCK_GLOBAL_IC:-1}
CLOUD_CONTROLLER_WORKER_IC=${CLOUD_CONTROLLER_WORKER_IC:-1}
DIEGO_DATABASE_IC=${DIEGO_DATABASE_IC:-1}
DIEGO_BRAIN_IC=${DIEGO_BRAIN_IC:-1}
DIEGO_CELL_IC=${DIEGO_CELL_IC:-3}
DOPPLER_IC=${DOPPLER_IC:-1}
LOGGREGATOR_TRAFFICCONTROLLER_IC=${LOGGREGATOR_TRAFFICCONTROLLER_IC:-1}
TCP_ROUTER_IC=${TCP_ROUTER_IC:-1}
PUSH_APPS_MANAGER_IC=${PUSH_APPS_MANAGER_IC:-1}
SMOKE_TESTS_IC=${SMOKE_TESTS_IC:-1}
NOTIFICATIONS_IC=${NOTIFICATIONS_IC:-1}
NOTIFICATIONS_UI_IC=${NOTIFICATIONS_UI_IC:-1}
AUTOSCALING_IC=${AUTOSCALING_IC:-1}
AUTOSCALING_REGISTER_BROKER_IC=${AUTOSCALING_REGISTER_BROKER_IC:-1}
AUTOSCALING_DESTROY_BROKER_IC=${AUTOSCALING_DESTROY_BROKER_IC:-1}
BOOTSTRAP_IC=${BOOTSTRAP_IC:-1}
PUSH_PIVOTAL_ACCOUNT_IC=${PUSH_PIVOTAL_ACCOUNT_IC:-1}
MYSQL_REJOIN_UNSAFE_IC=${MYSQL_REJOIN_UNSAFE_IC:-1}
        


#configure network and az

NETWORK_AND_AZ="$(source $ERT_TEMPLATE_DIR/$ERT_NETWORK_CONFIG_JSON)"
echo "===========================================Network and AZs Config==================================================="
echo "NETWORK_AND_AZ = $NETWORK_AND_AZ"
echo "=============================================================================================="
JOB_CONFIG="$(source $ERT_TEMPLATE_DIR/$ERT_JOBS_CONFIG_JSON)"
echo "===========================================Jobs Config==================================================="
echo "JOB_CONFIG = $JOB_CONFIG"
echo "=============================================================================================="
if [[ "$ERT_SSL" == "generate" ]]; then
  echo "=============================================================================================="
  echo "Generating Self Signed Certs for *.${ERT_SYSTEM_DOMAIN}, *.${ERT_APP_DOMAIN}, *.login.${ERT_SYSTEM_DOMAIN} and *.uaa.${ERT_SYSTEM_DOMAIN}"
  echo "=============================================================================================="
  pcf/pcf-automation/install-pcf/scripts/ssl/gen_ssl_certs.sh "${ERT_SYSTEM_DOMAIN}" "${ERT_APP_DOMAIN}"
  ERT_SSL_CERT=$(cat ${ERT_SYSTEM_DOMAIN}.crt)
  ERT_SSL_PRIVATE_KEY=$(cat ${ERT_SYSTEM_DOMAIN}.key)
  
fi

PROPERTIES="$(source $ERT_TEMPLATE_DIR/$ERT_PROPERTIES_JSON)"
echo "===========================================Ert Properties==================================================="
echo "PROPERTIES = $PROPERTIES"
echo "=============================================================================================="

#guid_cf=$(om -t https://$OPSMAN_HOST -k -u "$OPSMAN_USER" -p "$OPSMAN_PASSWORD" curl -x GET -p "/api/v0/staged/products" | jq '.[] | select(.type == "cf") | .guid' | tr -d '"' | grep "cf-.*")
# configure network and azs
echo "Executing om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n cf -pn \"${NETWORK_AND_AZ}\" ..."
om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n cf -pn "${NETWORK_AND_AZ}" 


# configure properties

echo "Executing om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n cf -p \"${PROPERTIES}\" ..."
om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n cf -p "${PROPERTIES}"

# configure jobs
echo "Executing om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n cf -pr \"${JOB_CONFIG}\" ..."
om -t https://$OPSMAN_HOST -k -u $OPSMAN_USER -p $OPSMAN_PASSWORD configure-product -n cf -pr "${JOB_CONFIG}"
