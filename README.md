## TERRAFORM with AWS ECS
*A sample terraform script to create/manage ECS on AWS*

### Dependency
Require [Terraform](https://www.terraform.io/)

Terraform version using in this repo is [0.9.6](https://releases.hashicorp.com/terraform/0.9.6/terraform_0.9.6_darwin_amd64.zip?)

### How To Run
Fill in requiere data in `configs.tfvars`, check for ECS task definition (including docker image file and container name) in `files/task_definitions.json`, set *route53_zone* and *domain* variables in `variables.tf`. Then

**Plan**

    terraform plan -var-file="configs.tfvars"

**Apply**

    terraform apply  -var-file="configs.tfvars"
    
**Destroy (!Careful!)** 

    terraform plan -destroy -var-file="configs.tfvars"
    terraform destroy -var-file="configs.tfvars"
    
### Summary
*This terraform script will do*
 - Add new VPC and Network
 - Add new IAM role to ECS service instance
 - Add new Network Security group to ECS instance
 - Add new ECS cluster
 - Add ECS task definition to cluster (using private Docker image on Docker Hub)
 - Configure Auto scaling with ECS, set ssh-key to new lauch instance
 - Setup ELB with ECS
 - Add New Route53 record to existed Route53 Zone, point new record to ELB DNS
 
### Summary Graph
[svg graph](https://github.com/hal2dy/terraform_aws_ecs/blob/master/graph.svg) 
