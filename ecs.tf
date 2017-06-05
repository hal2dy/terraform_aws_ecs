# ----------------------------------------------------------------
# DATA
# ----------------------------------------------------------------

provider "aws" {
    access_key  = "${var.access_key}"
    secret_key  = "${var.secret_key}"
    region      = "${var.region}"
}

data "template_file" "ecs" {
    template = "${file("files/bootstrap.sh")}"
    vars {
        cluster_name    = "${aws_ecs_cluster.terraform_new_cluster.name}"
        docker_host     = "${var.docker_host}"
        docker_auth     = "${var.docker_auth}"
        docker_email    = "${var.docker_email}"
    }
}


# ----------------------------------------------------------------
# SSH KEY
# ----------------------------------------------------------------

resource "aws_key_pair" "ssh_key" {
    key_name   = "hardy_key"
    public_key = "${var.ssh_key}"
}


# ----------------------------------------------------------------
# ECS 
# ----------------------------------------------------------------

resource "aws_ecs_cluster" "terraform_new_cluster" {
    name = "terraform_new_cluster"
}

resource "aws_ecs_task_definition" "terraform_new_task" {
    container_definitions   = "${file("files/task_definitions.json")}"
    family                  = "terraform_new_task"
}

data "aws_ecs_task_definition" "terraform_new_task" {
    task_definition = "${aws_ecs_task_definition.terraform_new_task.family}"
}

data "aws_ecs_container_definition" "terraform_new_ecs_container" {
    container_name  = "terraform_test_nginx_container"
    task_definition = "${aws_ecs_task_definition.terraform_new_task.id}"
}

resource "aws_ecs_service" "terraform_new_ecs_service" {
    name            = "terraform_new_ecs_service"
    cluster         = "${aws_ecs_cluster.terraform_new_cluster.id}"
    task_definition = "${aws_ecs_task_definition.terraform_new_task.family}:${max("${aws_ecs_task_definition.terraform_new_task.revision}", "${data.aws_ecs_task_definition.terraform_new_task.revision}")}"
    iam_role        = "${aws_iam_role.terraform_new_role.id}"
    desired_count   = 2
    load_balancer {
        elb_name        = "${aws_elb.terraform_elb_ecs.id}"
        container_name  = "terraform_test_nginx_container"
        container_port  = 80
    }
}

resource "aws_elb" "terraform_elb_ecs" {
    name            = "terraform-elb-ecs"
    subnets         = ["${aws_subnet.terraform_new_subnet.id}"]
    security_groups = ["${aws_security_group.terraform_new_security_group.id}"]
        listener = {
        lb_port             = 80
        lb_protocol         = "http"
        instance_port       = 80
        instance_protocol   = "http"
    }
    health_check {
        target              = "TCP:22"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 2
        interval            = 5
    }
    tags {
        Name = "terraform_elb_ecs-terraform-elb"
    }
}


# ----------------------------------------------------------------
# ECS LAUNCH
# ----------------------------------------------------------------

resource "aws_iam_instance_profile" "terraform_new_ingest" {
    name    = "terraform_new_ingest"
    roles   = ["${aws_iam_role.terraform_new_role.name}"]
}

resource "aws_iam_instance_profile" "terraform_iam_instance_profile" {
    name  = "terraform_iam_instance_profile"
    roles = ["${aws_iam_role.terraform_new_role.name}"]
    provisioner "local-exec" {
        command = "sleep 30" # wait for instance profile to appear
    }
}

resource "aws_launch_configuration" "terraform_ecs_instance" {
    name                        = "terraform_ecs_instance"
    instance_type               = "${var.instance_type}"
    image_id                    = "${lookup(var.ami, var.region)}"
    key_name                    = "${aws_key_pair.ssh_key.key_name}"
    security_groups             = ["${aws_security_group.terraform_new_security_group.id}"]
    iam_instance_profile        = "${aws_iam_instance_profile.terraform_iam_instance_profile.name}"
    user_data                   = "${data.template_file.ecs.rendered}"
    associate_public_ip_address = true
    security_groups = [
        "${aws_security_group.terraform_new_security_group.id}",
    ]
}

resource "aws_autoscaling_group" "terraform_esc_cluster_instances" {
    name                    = "terraform_esc_cluster_instances"
    launch_configuration    = "${aws_launch_configuration.terraform_ecs_instance.name}"
    vpc_zone_identifier     = ["${aws_subnet.terraform_new_subnet.id}"]
    load_balancers          = ["${aws_elb.terraform_elb_ecs.id}"]
    min_size                = 2
    max_size                = 2
    desired_capacity        = 2
    health_check_type       = "ELB"
    tag {
        key                 = "Name"
        value               = "terraform_ecs_instance"
        propagate_at_launch = true
    }
}


# ----------------------------------------------------------------
# VPC
# ----------------------------------------------------------------

resource "aws_vpc" "terraform_new_vpc" {
    cidr_block              = "10.0.0.0/16"
    enable_dns_hostnames    = true
    tags {
        Name = "terraform_new_vpc"
    }
}

resource "aws_subnet" "terraform_new_subnet" {
    vpc_id                  = "${aws_vpc.terraform_new_vpc.id}"
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "${var.availability_zone}"
    map_public_ip_on_launch = true
    tags {
        Name = "terraform_new_subnet"
    }
}

resource "aws_internet_gateway" "terraform_new_internet_gw" {
    vpc_id = "${aws_vpc.terraform_new_vpc.id}"
    tags {
        Name = "terraform_new_internet_gw"
    }
}

resource "aws_route_table" "terraform_new_routetable" {
    vpc_id = "${aws_vpc.terraform_new_vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.terraform_new_internet_gw.id}"
    }
    tags {
        Name = "terraform_new_routetable"
    }
}

resource "aws_route_table_association" "terraform_new_route_tableassociate" {
    subnet_id       = "${aws_subnet.terraform_new_subnet.id}"
    route_table_id  = "${aws_route_table.terraform_new_routetable.id}"
}


# ----------------------------------------------------------------
# SECURITY GROUP
# ----------------------------------------------------------------

resource "aws_security_group" "terraform_new_security_group" {
    name        = "terraform_new_security_group"
    description = "Allow SSH & HTTP to web hosts"
    vpc_id      = "${aws_vpc.terraform_new_vpc.id}"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # HTTP access from the VPC
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


# ----------------------------------------------------------------
# ROLE
# ----------------------------------------------------------------

resource "aws_iam_role" "terraform_new_role" {
    name                = "terraform_new_role"
    assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com", "ecs.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "terraform_new_ecs_policy" {
    name    = "terraform_new_ecs_policy"
    role    = "${aws_iam_role.terraform_new_role.id}"
    policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:UpdateContainerInstancesState",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DescribeInstanceHealth"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


# ----------------------------------------------------------------
# ROUTE 53
# ----------------------------------------------------------------

data "aws_route53_zone" "terraform_route53_zone" {
    name = "${var.route53_zone}."
}

resource "aws_route53_record" "terraform_new_route53" {
    zone_id = "${data.aws_route53_zone.terraform_route53_zone.zone_id}"
    name    = "${var.domain}.${data.aws_route53_zone.terraform_route53_zone.name}"
    type    = "A"
    alias {
        name                   = "${aws_elb.terraform_elb_ecs.dns_name}"
        zone_id                = "${aws_elb.terraform_elb_ecs.zone_id}"
        evaluate_target_health = true
    }
}