#!/bin/bash
set -ex
cp /terraform /usr/local/bin
CWD=$(pwd)

# get values from pcfawsops-terraform-state-get
cd pcfawsops-terraform-state-get
export TF_VAR_vpc_cidr=`terraform output | grep ^vpc_cidr | awk '{print $3}'`
export TF_VAR_vpc_id=`terraform output | grep ^vpc_id | awk '{print $3}'`
export TF_VAR_environment=`terraform output | grep ^environment | awk '{print $3}'`
export TF_VAR_aws_region=`terraform output | grep ^region | awk '{print $3}'`

cd $CWD
if [[ -s $CWD/aws-sb-terraform-state-get/$S3_AWS_SB_TF_STATE_FILE_NAME ]]; then
    cp $CWD/aws-sb-terraform-state-get/$S3_AWS_SB_TF_STATE_FILE_NAME pcf-automation/pcf-opsman/install-pcf/iaas_config/aws-service-broker/terraform.tfstate
fi

cd pcf-automation/pcf-opsman/install-pcf/iaas_config/aws-service-broker
terraform plan
terraform apply
cp terraform.tfstate $CWD/aws-sb-terraform-state-put/$S3_AWS_SB_TF_STATE_FILE_NAME
