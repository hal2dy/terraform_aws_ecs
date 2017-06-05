# ----------------------------------------------------------------
# OUT
# ----------------------------------------------------------------
output "address" {
    value = "${aws_route53_record.terraform_new_route53.name}"
}

output "elb_dns" {
    value = "${aws_elb.terraform_elb_ecs.dns_name}"
}