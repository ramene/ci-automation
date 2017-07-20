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
export TF_VAR_service_subnet1=`terraform output | grep ^services_subnet_id_az1 | awk '{print $3}'`
export TF_VAR_service_subnet2=`terraform output | grep ^services_subnet_id_az2 | awk '{print $3}'`
export TF_VAR_service_subnet3=`terraform output | grep ^services_subnet_id_az3 | awk '{print $3}'`

if [[ -s $CWD/rabbitmq-terraform-state-get/$S3_RABBITMQ_TF_STATE_FILE_NAME ]]; then
    cp $CWD/rabbitmq-terraform-state-get/$S3_RABBITMQ_TF_STATE_FILE_NAME pcf-automation/pcf-opsman/install-pcf/iaas_config/rabbitmq/terraform.tfstate
fi

cd $CWD/pcf-automation/pcf-opsman/install-pcf/iaas_config/rabbit
terraform plan
terraform apply
cp terraform.tfstate $CWD/rabbitmq-terraform-state-put/$S3_RABBITMQ_TF_STATE_FILE_NAME
