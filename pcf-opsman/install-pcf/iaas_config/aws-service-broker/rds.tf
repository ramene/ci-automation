resource "aws_db_instance" "pcf_rds" {
    identifier              = "pcf-aws-services"
    allocated_storage       = 100
    engine                  = "mysql"
    engine_version          = "5.6.27"
    iops                    = 1000
    instance_class          = "db.t2.micro"
    name                    = "pcf_aws_services"
    username                = "${var.rds_db_username}"
    password                = "${var.rds_db_password}"
    db_subnet_group_name    = "${var.environment}-rds_subnet_group"
    parameter_group_name    = "default.mysql5.6"
    vpc_security_group_ids  = ["${aws_security_group.rds_broker_SG.id}"]
    multi_az                = true
    backup_retention_period = 7
    apply_immediately       = true
}
