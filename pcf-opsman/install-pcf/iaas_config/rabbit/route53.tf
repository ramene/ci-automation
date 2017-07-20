resource "aws_route53_zone" "SonicInternalForPcf" {
    name = "sonicdrivein.internal"
    comment = "Internal zone for Pcf - rabbitmq"
    vpc_id = "${var.vpc_id}"
}
resource "aws_route53_record" "pcf-rabbitmq-internal" {
    zone_id = "${aws_route53_zone.SonicInternalForPcf.zone_id}"
    name = "queue.sonicdrivein.internal"
    type = "CNAME"
    ttl = "30"
    records = [
        "${aws_elb.PcfRabbitElbInt.dns_name}"
    ]
}
