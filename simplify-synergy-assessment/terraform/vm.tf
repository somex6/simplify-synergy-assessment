module "vm_instance" {
  source = "./modules/vm"

  name                        = var.vm_name
  ami                         = var.ami
  create_iam_instance_profile = var.create_iam_instance_profile
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.private_subnets[0]
  metadata_options            = var.metadata_options

  tags = var.tags
}