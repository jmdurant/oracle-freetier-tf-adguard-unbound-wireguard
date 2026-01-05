# =============================================================================
# OCI Vault Configuration for AIOTP Secrets Management
# =============================================================================
# This creates:
# - OCI Vault for storing secrets
# - Master encryption key
# - All application secrets
# - Dynamic Group for instance principal access
# - IAM Policy granting vault access to compute instances
# =============================================================================

# -----------------------------------------------------------------------------
# Vault and Master Key
# -----------------------------------------------------------------------------

resource "oci_kms_vault" "aiotp_vault" {
  compartment_id = var.tenancy_ocid
  display_name   = "aiotp-secrets-vault"
  vault_type     = "DEFAULT"  # Use "VIRTUAL_PRIVATE" for higher security (paid)
}

resource "oci_kms_key" "aiotp_master_key" {
  compartment_id = var.tenancy_ocid
  display_name   = "aiotp-master-key"
  key_shape {
    algorithm = "AES"
    length    = 32  # 256-bit key
  }
  management_endpoint = oci_kms_vault.aiotp_vault.management_endpoint
  protection_mode     = "SOFTWARE"  # Use "HSM" for hardware protection (paid)
}

# -----------------------------------------------------------------------------
# Dynamic Group for Instance Principal Authentication
# -----------------------------------------------------------------------------

resource "oci_identity_dynamic_group" "aiotp_compute_group" {
  compartment_id = var.tenancy_ocid
  name           = "aiotp-compute-instances"
  description    = "Dynamic group for AIOTP compute instances to access vault secrets"

  # Match all instances in the compartment (adjust as needed for specific instances)
  matching_rule = "ALL {instance.compartment.id = '${var.tenancy_ocid}'}"

  # Alternative: Match specific instance by OCID
  # matching_rule = "ANY {instance.id = '${var.compute_instance_ocid}'}"
}

# -----------------------------------------------------------------------------
# IAM Policy for Vault Access
# -----------------------------------------------------------------------------

resource "oci_identity_policy" "aiotp_vault_policy" {
  compartment_id = var.tenancy_ocid
  name           = "aiotp-vault-access-policy"
  description    = "Policy allowing AIOTP compute instances to read vault secrets"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.aiotp_compute_group.name} to read secret-family in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.aiotp_compute_group.name} to use vaults in tenancy",
    "Allow dynamic-group ${oci_identity_dynamic_group.aiotp_compute_group.name} to use keys in tenancy",
  ]
}

# -----------------------------------------------------------------------------
# Secrets - Database
# -----------------------------------------------------------------------------

resource "oci_vault_secret" "database_openemr_password" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "database-openemr-password"
  description    = "OpenEMR MySQL root password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_database_openemr_password)
  }
}

resource "oci_vault_secret" "database_telehealth_password" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "database-telehealth-password"
  description    = "Telehealth database password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_database_telehealth_password)
  }
}

# -----------------------------------------------------------------------------
# Secrets - OpenEMR
# -----------------------------------------------------------------------------

resource "oci_vault_secret" "openemr_notification_token" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "openemr-notification-token"
  description    = "OpenEMR notification token"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_openemr_notification_token)
  }
}

# -----------------------------------------------------------------------------
# Secrets - Telehealth
# -----------------------------------------------------------------------------

resource "oci_vault_secret" "telehealth_app_key" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "telehealth-app-key"
  description    = "Laravel APP_KEY for telehealth"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_telehealth_app_key)
  }
}

resource "oci_vault_secret" "telehealth_notification_token" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "telehealth-notification-token"
  description    = "Telehealth notification token"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_telehealth_notification_token)
  }
}

resource "oci_vault_secret" "telehealth_webhook_secret" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "telehealth-webhook-secret"
  description    = "Telehealth HMAC webhook secret"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_telehealth_webhook_secret)
  }
}

resource "oci_vault_secret" "telehealth_transcription_token" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "telehealth-transcription-token"
  description    = "Telehealth transcription notification token"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_telehealth_transcription_token)
  }
}

resource "oci_vault_secret" "telehealth_redis_password" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "telehealth-redis-password"
  description    = "Telehealth Redis password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_telehealth_redis_password)
  }
}

# -----------------------------------------------------------------------------
# Secrets - Mail
# -----------------------------------------------------------------------------

resource "oci_vault_secret" "mail_smtp_password" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "mail-smtp-password"
  description    = "SMTP mail password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_mail_smtp_password)
  }
}

# -----------------------------------------------------------------------------
# Secrets - Pusher
# -----------------------------------------------------------------------------

resource "oci_vault_secret" "pusher_app_id" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "pusher-app-id"
  description    = "Pusher application ID"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_pusher_app_id)
  }
}

resource "oci_vault_secret" "pusher_app_key" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "pusher-app-key"
  description    = "Pusher application key"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_pusher_app_key)
  }
}

resource "oci_vault_secret" "pusher_app_secret" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "pusher-app-secret"
  description    = "Pusher application secret"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_pusher_app_secret)
  }
}

# -----------------------------------------------------------------------------
# Secrets - Firebase
# -----------------------------------------------------------------------------

resource "oci_vault_secret" "firebase_webhook_secret" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "firebase-webhook-secret"
  description    = "Firebase webhook secret"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_firebase_webhook_secret)
  }
}

# -----------------------------------------------------------------------------
# Secrets - Jitsi
# -----------------------------------------------------------------------------

resource "oci_vault_secret" "jitsi_jwt_app_secret" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "jitsi-jwt-app-secret"
  description    = "Jitsi JWT application secret"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_jitsi_jwt_app_secret)
  }
}

resource "oci_vault_secret" "jitsi_sip_password" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "jitsi-sip-password"
  description    = "Jigasi SIP password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_jitsi_sip_password)
  }
}

resource "oci_vault_secret" "jitsi_jicofo_password" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "jitsi-jicofo-password"
  description    = "Jicofo auth password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_jitsi_jicofo_password)
  }
}

resource "oci_vault_secret" "jitsi_jvb_password" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "jitsi-jvb-password"
  description    = "JVB auth password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_jitsi_jvb_password)
  }
}

resource "oci_vault_secret" "jitsi_jigasi_xmpp_password" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "jitsi-jigasi-xmpp-password"
  description    = "Jigasi XMPP password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_jitsi_jigasi_xmpp_password)
  }
}

resource "oci_vault_secret" "jitsi_jigasi_transcriber_password" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "jitsi-jigasi-transcriber-password"
  description    = "Jigasi transcriber password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_jitsi_jigasi_transcriber_password)
  }
}

resource "oci_vault_secret" "jitsi_jibri_recorder_password" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "jitsi-jibri-recorder-password"
  description    = "Jibri recorder password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_jitsi_jibri_recorder_password)
  }
}

resource "oci_vault_secret" "jitsi_jibri_xmpp_password" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "jitsi-jibri-xmpp-password"
  description    = "Jibri XMPP password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_jitsi_jibri_xmpp_password)
  }
}

resource "oci_vault_secret" "jitsi_turn_password" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "jitsi-turn-password"
  description    = "TURN server password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_jitsi_turn_password)
  }
}

# -----------------------------------------------------------------------------
# Secrets - Transcription
# -----------------------------------------------------------------------------

resource "oci_vault_secret" "transcription_webhook_token" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "transcription-webhook-token"
  description    = "Transcription pipeline webhook token"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_transcription_webhook_token)
  }
}

# -----------------------------------------------------------------------------
# Secrets - GitHub
# -----------------------------------------------------------------------------

resource "oci_vault_secret" "github_token_main" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "github-token-main"
  description    = "GitHub personal access token (main)"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_github_token_main)
  }
}

resource "oci_vault_secret" "github_token_wordpress" {
  compartment_id = var.tenancy_ocid
  vault_id       = oci_kms_vault.aiotp_vault.id
  key_id         = oci_kms_key.aiotp_master_key.id
  secret_name   = "github-token-wordpress"
  description    = "GitHub personal access token (wordpress)"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.secret_github_token_wordpress)
  }
}

# -----------------------------------------------------------------------------
# Outputs (moved to outputs.tf for centralized output management)
# -----------------------------------------------------------------------------
# See outputs.tf for all terraform outputs
