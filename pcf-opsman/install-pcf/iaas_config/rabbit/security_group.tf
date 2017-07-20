/*
  Security Group Definitions for Elastic Load Balancers
*/

resource "aws_security_group" "PcfRabbitElbSg" {
    name = "${var.environment}-pcf_PcfRabbitElb_sg"
    description = "Allow incoming connections for PcfRabbitElb Elb."
    vpc_id = "${var.vpc_id}"
    tags {
        Name = "${var.environment}-PcfRabbitElb Security Group"
    }
    ingress {
        from_port = 5672
        to_port = 5672
        protocol = "TCP"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    ingress {
        from_port = 5671
        to_port = 5671
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 15672
        to_port = 15672
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 4567
        to_port = 4567
        protocol = "TCP"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    ingress {
        from_port = 3457
        to_port = 3457
        protocol = "TCP"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    ingress {
        from_port = 3458
        to_port = 3458
        protocol = "TCP"
        cidr_blocks = ["${var.vpc_cidr}"]
    }
    ingress {
        from_port = 3459
        to_port = 3459
        protocol = "TCP"
        cidr_blocks = ["${var.vpc_cidr}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}
