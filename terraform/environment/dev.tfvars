aws_region = "us-east-1"
tags = {
  environment = "dev"
  purpose     = "Assessment"
}

# VPC variable
vpc_name        = "simplify-synergy-project"
vpc_cidr        = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24"]
a_zones         = ["us-east-1b"]

# VM Variable
vm_name       = "ss-bastion"
ami           = "ami-04e5276ebb8451442"
instance_type = "t2.micro"

# IAM Users
username = "iwekasomto@gmail.com"
path     = "/"
