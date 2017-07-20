#!/bin/bash
set -e

echo "$PEM" > pcf.pem
chmod 0600 pcf.pem

mv /terraform /usr/local/bin
CWD=$(pwd)
pushd $CWD
  cd pcf-automation/pcf-opsman/install-pcf/iaas_config/aws/
  cp $CWD/pcfawsops-terraform-state-get/terraform.tfstate .

  while read -r line
  do
    `echo "$line" | awk '{print "export "$1"="$3}'`
  done < <(terraform output)

  export RDS_PASSWORD=`terraform state show aws_db_instance.pcf_rds | grep ^password | awk '{print $3}'`
popd

scp -i pcf.pem -o StrictHostKeyChecking=no pcf-automation/pcf-opsman/install-pcf/ci/scripts/databases.sql ubuntu@${OPSMAN_HOST}:/tmp/.
ssh -i pcf.pem -o StrictHostKeyChecking=no ubuntu@${OPSMAN_HOST} "mysql -h $db_host -u $db_username --password=$RDS_PASSWORD < /tmp/databases.sql"
