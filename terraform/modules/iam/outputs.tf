locals {
  has_encrypted_password = length(compact(aws_iam_user_login_profile.this[*].encrypted_password)) > 0
  has_encrypted_secret   = length(compact(aws_iam_access_key.this[*].encrypted_secret)) > 0
}

output "keybase_password_pgp_message" {
  description = "Encrypted password"
  value       = !local.has_encrypted_password ? null : <<EOF
-----BEGIN PGP MESSAGE-----
Version: Keybase OpenPGP v2.0.76
Comment: https://keybase.io/crypto

${try(aws_iam_user_login_profile.this[0].encrypted_password, "")}
-----END PGP MESSAGE-----
EOF

}

output "keybase_secret_key_pgp_message" {
  description = "Encrypted access secret key"
  value       = !local.has_encrypted_secret ? null : <<EOF
-----BEGIN PGP MESSAGE-----
Version: Keybase OpenPGP v2.0.76
Comment: https://keybase.io/crypto

${try(aws_iam_access_key.this[0].encrypted_secret, "")}
-----END PGP MESSAGE-----
EOF

}

output "policy_arns" {
  description = "The list of ARNs of policies directly assigned to the IAM user"
  value       = [for policy_attachment in aws_iam_user_policy_attachment.this : policy_attachment.policy_arn]
}
