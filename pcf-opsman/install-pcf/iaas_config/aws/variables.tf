variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_name" {}
variable "aws_cert_arn" {}
variable "rds_db_username" {}
variable "rds_db_password" {}
variable "environment" {}
variable "opsman_ami" {}
variable "amis_nat" {}
variable "aws_region" {}
variable "az1" {}
variable "az2" {}
variable "az3" {}

variable "opsman_instance_type" {
    description = "Instance Type for OpsMan"
    default = "m3.large"
}
variable "nat_instance_type" {
    description = "Instance Type for NAT instances"
    default = "t2.medium"
}
variable "db_instance_type" {
    description = "Instance Type for RDS instance"
    default = "db.m3.large"
}

variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "10.3.0.0/16"
}
/*
  Availability Zone 1
*/

# public subnet
variable "public_subnet_cidr_az1" {
    description = "CIDR for the Public Subnet 1"
    default = "10.3.0.0/24"
}
# ERT subnet
variable "ert_subnet_cidr_az1" {
    description = "CIDR for the Private Subnet 1"
    default = "10.3.16.0/20"
}
# RDS subnet
variable "rds_subnet_cidr_az1" {
    description = "CIDR for the RDS Subnet 1"
    default = "10.3.3.0/24"
}
# Services subnet
variable "services_subnet_cidr_az1" {
    description = "CIDR for the Services Subnet 1"
    default = "10.3.64.0/20"
}

variable "nat_ip_az1" {
    default = "10.3.0.6"
}
variable "opsman_ip_az1" {
    default = "10.3.0.7"
}

/*
  Availability Zone 2
*/


variable "public_subnet_cidr_az2" {
    description = "CIDR for the Public Subnet 2"
    default = "10.3.1.0/24"
}
variable "ert_subnet_cidr_az2" {
    description = "CIDR for the Private Subnet 2"
    default = "10.3.32.0/20"
}
# RDS subnet
variable "rds_subnet_cidr_az2" {
    description = "CIDR for the RDS Subnet 2"
    default = "10.3.4.0/24"
}
# Services subnet
variable "services_subnet_cidr_az2" {
    description = "CIDR for the Services Subnet 2"
    default = "10.3.80.0/20"
}

variable "nat_ip_az2" {
    default = "10.3.1.6"
}

/*
  Availability Zone 3
*/
variable "public_subnet_cidr_az3" {
    description = "CIDR for the Public Subnet 3"
    default = "10.3.2.0/24"
}
variable "ert_subnet_cidr_az3" {
    description = "CIDR for the Private Subnet 3"
    default = "10.3.48.0/20"
}
# RDS subnet
variable "rds_subnet_cidr_az3" {
    description = "CIDR for the RDS Subnet 3"
    default = "10.3.5.0/24"
}
# Services subnet
variable "services_subnet_cidr_az3" {
    description = "CIDR for the Services Subnet 3"
    default = "10.3.96.0/20"
}

variable "nat_ip_az3" {
    default = "10.3.2.6"
}
