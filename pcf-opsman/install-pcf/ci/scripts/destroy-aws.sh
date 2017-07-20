#!/bin/bash
set -ex

mv /terraform /usr/local/bin
CWD=$(pwd)

cd pcf-automation/pcf-opsman/install-pcf/iaas_config/aws/
cp $CWD/pcfawsops-terraform-state-get/terraform.tfstate .

terraform plan
terraform destroy -force

cd $CWD/pcfawsops-terraform-state-put
touch terraform.tfstate
