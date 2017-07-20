#!/bin/bash
set -ex

echo "$OPSMAN_PEM" > pcf.pem
chmod 600 pcf.pem

cp /om-alpine /usr/local/bin

om-alpine --target https://$OPSMAN_HOST -k --username "$OPSMAN_USER" --password "$OPSMAN_PASSWORD" export-installation -o pcfawsops_backup_opsman_put/$(date +%Y-%m-%d:%H:%M:%S-ops-manager.zip)

ssh -i pcf.pem -o StrictHostKeyChecking=no ubuntu@${OPSMAN_HOST} 'sudo find /tmp -user tempest-web -type f ! -name "*.log" -exec rm {} \;'

