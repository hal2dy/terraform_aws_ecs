variable "access_key" {
    description = "The AWS access key."
} 

variable "secret_key" {
    description = "The AWS secret key."
}

variable "region" {
    type = "string"
    description = "The AWS region."
    default = "ap-southeast-1"
}

variable "availability_zone" {
    type = "string"
    description = "VPC available zone"
    default = "ap-southeast-1a"
}

variable "ami" {
    type = "map"
    default = { 
        ap-southeast-1 = "ami-b4ae1dd7"
    }
    description = "ECS AMIs to use."
}

variable "instance_type" {
    description = "The instance type."
    default = "t2.micro" 
}

variable "ssh_key" {
    description = "The AWS key pair to use for resources."
}

variable "route53_zone" {
    type = "string"
    description = "Route 53 Zone"
    default = "core.zalora.io"
}

variable "domain" {
    description = "Route53 domain for ELB"
    default = "hungtest"
}

variable "docker_host" {
    type = "string"
    description = "Docker host"
    default = "https://index.docker.io/v1/"
}

variable "docker_email" {
    description = "Docker host login username"
}

variable "docker_auth" {
    description = "Docker host login authentication"
}