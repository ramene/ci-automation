/*
  Security Group Definitions
*/

/*
  RDS Security group
*/
resource "aws_security_group" "rds_broker_SG" {
    name = "${var.environment}-aws_service_broker_rds_sg"
    description = "Allow incoming connections for RDS."
    vpc_id = "${var.vpc_id}"
    tags {
        Name = "${var.environment}-RDS Security Group"
    }
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    ingress {
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }

}
