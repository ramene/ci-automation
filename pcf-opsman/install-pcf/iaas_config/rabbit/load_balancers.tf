resource "aws_elb" "PcfRabbitElb" {
  name = "${var.environment}-Pcf-Rabbit-Elb"
  subnets = ["${var.service_subnet1}","${var.service_subnet2}","${var.service_subnet3}"]
  security_groups = ["${aws_security_group.PcfRabbitElbSg.id}"]

  listener {
    instance_port = 5672
    instance_protocol = "TCP"
    lb_port = 5672
    lb_protocol = "TCP"
  }

  listener {
    instance_port = 5672
    instance_protocol = "TCP"
    lb_port = 5671
    lb_protocol = "SSL"
    ssl_certificate_id = "${var.aws_cert_arn}"
  }

  listener {
    instance_port = 15672
    instance_protocol = "HTTP"
    lb_port = 15672
    lb_protocol = "HTTP"
  }

  listener {
    instance_port = 4567
    instance_protocol = "TCP"
    lb_port = 4567
    lb_protocol = "SSL"
    ssl_certificate_id = "${var.aws_cert_arn}"
  }

  listener {
    instance_port = 3457
    instance_protocol = "TCP"
    lb_port = 3457
    lb_protocol = "TCP"
  }

  listener {
    instance_port = 3458
    instance_protocol = "TCP"
    lb_port = 3458
    lb_protocol = "TCP"
  }
  listener {
    instance_port = 3459
    instance_protocol = "TCP"
    lb_port = 3459
    lb_protocol = "TCP"
  }

  health_check {
    target = "TCP:5672"
    timeout = 5
    interval = 30
    unhealthy_threshold = 2
    healthy_threshold = 10
  }
  tags {
    Name = "${var.environment}-Pcf Rabbit Elb"
  }
}
resource "aws_elb" "PcfRabbitElbInt" {
  name = "${var.environment}-Pcf-Rabbit-Elb-Int"
  subnets = ["${var.service_subnet1}","${var.service_subnet2}","${var.service_subnet3}"]
  security_groups = ["${aws_security_group.PcfRabbitElbSg.id}"]
  internal = "true"

  listener {
    instance_port = 5672
    instance_protocol = "TCP"
    lb_port = 5672
    lb_protocol = "TCP"
  }
/*
  listener {
    instance_port = 5672
    instance_protocol = "TCP"
    lb_port = 5671
    lb_protocol = "SSL"
    ssl_certificate_id = "${var.aws_cert_arn}"
  }
*/
  listener {
    instance_port = 15672
    instance_protocol = "HTTP"
    lb_port = 15672
    lb_protocol = "HTTP"
  }
/*
  listener {
    instance_port = 4567
    instance_protocol = "TCP"
    lb_port = 4567
    lb_protocol = "SSL"
    ssl_certificate_id = "${var.aws_cert_arn}"
  }
*/
  listener {
    instance_port = 4567
    instance_protocol = "TCP"
    lb_port = 4567
    lb_protocol = "TCP"
  }
  listener {
    instance_port = 3457
    instance_protocol = "TCP"
    lb_port = 3457
    lb_protocol = "TCP"
  }

  listener {
    instance_port = 3458
    instance_protocol = "TCP"
    lb_port = 3458
    lb_protocol = "TCP"
  }
  listener {
    instance_port = 3459
    instance_protocol = "TCP"
    lb_port = 3459
    lb_protocol = "TCP"
  }

  health_check {
    target = "TCP:5672"
    timeout = 5
    interval = 30
    unhealthy_threshold = 2
    healthy_threshold = 10
  }
  tags {
    Name = "${var.environment}-Pcf Rabbit Elb Internal"
  }
}
