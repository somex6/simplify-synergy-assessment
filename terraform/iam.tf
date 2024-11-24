module "iam_users" {
  source = "./modules/iam"

  name          = var.username
  path          = var.path
  force_destroy = var.force_destroy
}