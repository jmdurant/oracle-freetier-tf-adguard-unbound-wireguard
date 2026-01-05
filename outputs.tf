# =============================================================================
# Terraform Outputs for AIOTP Infrastructure
# =============================================================================

# -----------------------------------------------------------------------------
# Vault Outputs
# -----------------------------------------------------------------------------

output "vault_id" {
  description = "OCID of the AIOTP secrets vault"
  value       = oci_kms_vault.aiotp_vault.id
}

output "vault_management_endpoint" {
  description = "Vault management endpoint URL"
  value       = oci_kms_vault.aiotp_vault.management_endpoint
}

output "vault_crypto_endpoint" {
  description = "Vault crypto endpoint URL"
  value       = oci_kms_vault.aiotp_vault.crypto_endpoint
}

output "master_key_id" {
  description = "OCID of the master encryption key"
  value       = oci_kms_key.aiotp_master_key.id
}

output "dynamic_group_id" {
  description = "OCID of the dynamic group for instance principal access"
  value       = oci_identity_dynamic_group.aiotp_compute_group.id
}

output "vault_policy_id" {
  description = "OCID of the vault access policy"
  value       = oci_identity_policy.aiotp_vault_policy.id
}

output "dynamic_group_name" {
  description = "Name of the dynamic group for instance principal access"
  value       = oci_identity_dynamic_group.aiotp_compute_group.name
}

output "vault_secrets_command" {
  description = "Example OCI CLI command for retrieving secrets (use in start-deployment-simple.sh)"
  value       = "oci secrets secret-bundle get-secret-bundle-by-name --vault-id ${oci_kms_vault.aiotp_vault.id} --secret-name <SECRET_NAME> --auth instance_principal"
}

# -----------------------------------------------------------------------------
# Legacy Outputs (Commented - uncomment when deploying full infrastructure)
# -----------------------------------------------------------------------------

# output "instance_id" {
#   description = "ocid of created instances. "
#   value       = [oci_core_instance.adguard_instance.id]
# }

# output "private_ip" {
#   description = "Private IPs of created instances. "
#   value       = [oci_core_instance.adguard_instance.private_ip]
# }

# output "public_ip" {
#   description = "Public IPs of created instances. "
#   value       = [oci_core_instance.adguard_instance.public_ip]
# }

# output "adguard_bucket_id" {
#   value = oci_objectstorage_bucket.adguard_bucket.id
# }
# output "adguard_archive_bucket_id" {
#   value = oci_objectstorage_bucket.adguard_archive_bucket.id
# }
