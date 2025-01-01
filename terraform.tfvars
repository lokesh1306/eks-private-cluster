region                = "us-east-1"
project_name          = "eks"
env                   = "prod"
vpc_cidr              = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
azs                   = ["us-east-1a", "us-east-1b", "us-east-1c"]
cluster_name          = "eks"
cluster_version       = "1.30"
bastion_ami_id        = "ami-01816d07b1128cd2d"
bastion_instance_type = "t2.micro"
karpenter_name        = "karpenter"