#!/bin/bash
set -ex

echo "Stopping Cloud Controller(s) ..."

echo "$ROOT_CA" > root_ca_certificate

bosh --ca-cert root_ca_certificate -n target $BOSH_DIRECTOR_IP

# get bosh deployments
deployments=$(bosh deployments | awk -F'|' '{print $2}' | tr -d ' ' | grep -v ^$ | grep -v Name)

while read -r deployment; 
do
  bosh download manifest $deployment > $deployment.yml
done <<< "$deployments"

cf_deployment=$(ls cf*)

bosh deployment $cf_deployment
bosh -n stop cloud_controller

echo "Stopped Cloud Controller(s)"
