#!/bin/bash
set -ex
cp /terraform /usr/local/bin
CWD=$(pwd)
cd pcf-automation/pcf-opsman/install-pcf/iaas_config/aws/
if [[ -s $CWD/pcfawsops-terraform-state-get/terraform.tfstate ]]; then
    cp $CWD/pcfawsops-terraform-state-get/terraform.tfstate .
fi
terraform plan
terraform apply
cp terraform.tfstate $CWD/pcfawsops-terraform-state-put/terraform.tfstate
