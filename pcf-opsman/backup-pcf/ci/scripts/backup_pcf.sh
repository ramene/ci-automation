#!/bin/bash
set -ex

cp /terraform /usr/local/bin

echo "$ROOT_CA" > root_ca_certificate
echo "$OPSMAN_PEM" > pcf.pem
chmod 600 pcf.pem

# download bash manifests
bosh --ca-cert root_ca_certificate -n target $BOSH_DIRECTOR_IP

# get bosh deployments
deployments=$(bosh deployments | awk -F'|' '{print $2}' | tr -d ' ' | grep -v ^$ | grep -v Name)

while read -r deployment; 
do
  bosh download manifest $deployment > $deployment.yml
done <<< "$deployments"

tar cvzf pcfawsops_backup_pcf_put/$(date +%Y-%m-%d:%H:%M:%S)-deployment-manifest.tgz *.yml

# backup bosh db
CWD=$(pwd)

cp $CWD/pcfawsops-terraform-state-get/terraform.tfstate .

while read -r line
do
  `echo "$line" | awk '{print "export "$1"="$3}'`
done < <(terraform output)

export db_password=`terraform state show aws_db_instance.pcf_rds | grep ^password | awk '{print $3}'`

ssh -i pcf.pem -o StrictHostKeyChecking=no ubuntu@${OPSMAN_HOST} "mysqldump -h $db_host -u $db_username --password=$db_password --all-databases > /tmp/pcf_db.sql"
scp -i pcf.pem -o StrictHostKeyChecking=no  ubuntu@${OPSMAN_HOST}:/tmp/pcf_db.sql .
mv pcf_db.sql "$(date +%Y-%m-%d:%H:%M:%S)-pcf-db.sql"

tar cvzf pcfawsops_backup_pcf_put/$(date +%Y-%m-%d:%H:%M:%S)-pcf-db.tgz *.sql

# backup s3 filestore

CWD=$(pwd)
mkdir s3_backup
mkdir s3_backup/$s3_pcf_bosh
mkdir s3_backup/$s3_buildpacks
mkdir s3_backup/$s3_pcf_droplets
mkdir s3_backup/$s3_pcf_packages
mkdir s3_backup/$s3_pcf_resources

s3cmd sync s3://$s3_pcf_bosh s3_backup/$s3_pcf_bosh
s3cmd sync s3://$s3_buildpacks s3_backup/$s3_buildpacks
s3cmd sync s3://$s3_pcf_droplets s3_backup/$s3_pcf_droplets
s3cmd sync s3://$s3_pcf_packages s3_backup/$s3_pcf_packages
s3cmd sync s3://$s3_pcf_resources s3_backup/$s3_pcf_resources


tar cvzf pcfawsops_backup_pcf_put/$(date +%Y-%m-%d:%H:%M:%S)-pcf-s3-buckets.tgz s3_backup

tar cvzf $(date +%Y-%m-%d:%H:%M:%S)-pcf-backup.tgz pcfawsops_backup_pcf_put/*.tgz

rm pcfawsops_backup_pcf_put/*

mv *-pcf-backup.tgz pcfawsops_backup_pcf_put/



