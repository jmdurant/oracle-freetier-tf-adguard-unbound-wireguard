variable "oracle_api_key_fingerprint" {}
variable "oracle_api_private_key_path" {}

variable "ssh_public_key" {}
variable "ssh_private_key_path" {}
variable "tenancy_ocid" {}
variable "user_ocid" {}

variable "region" {}

variable "instance_display_name" {
  default = "adguard"
}

variable "vcn_cidr_block" {
  default = "10.1.0.0/16"
}

variable "availability_domain_number" {
  default = 2
}

variable "instance_shape" {
  # Free-Tier is VM.Standard.E2.1.Micro
  default = "VM.Standard.E2.1.Micro"
}


variable "instance_image_ocid" {
  type = map

  default = {
    # See https://docs.oracle.com/en-us/iaas/images/ubuntu-2004/
    # Oracle-provided image "Canonical-Ubuntu-20.04-2021.02.15-0"
    uk-london-1      = "ocid1.image.oc1.uk-london-1.aaaaaaaa7vf2q5jtvzmniylmssuyrczkxw64wl4mlat4kh2fprquuosgficq"
    us-ashburn-1     = "ocid1.image.oc1.iad.aaaaaaaalukjk3ut7ibmrfphe6g2klmcl4hodvapraj2e4frw4bjsqswts2q"
  }
}

# =============================================================================
# Vault Secrets Variables
# =============================================================================
# These are passed via terraform.tfvars or environment variables (TF_VAR_*)
# NEVER commit actual secret values to source control!
# =============================================================================

# Database secrets
variable "secret_database_openemr_password" {
  description = "OpenEMR MySQL root password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_database_telehealth_password" {
  description = "Telehealth database password"
  type        = string
  sensitive   = true
  default     = ""
}

# OpenEMR secrets
variable "secret_openemr_notification_token" {
  description = "OpenEMR notification token"
  type        = string
  sensitive   = true
  default     = ""
}

# Telehealth secrets
variable "secret_telehealth_app_key" {
  description = "Laravel APP_KEY for telehealth"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_telehealth_notification_token" {
  description = "Telehealth notification token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_telehealth_webhook_secret" {
  description = "Telehealth HMAC webhook secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_telehealth_transcription_token" {
  description = "Telehealth transcription notification token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_telehealth_redis_password" {
  description = "Telehealth Redis password"
  type        = string
  sensitive   = true
  default     = ""
}

# Mail secrets
variable "secret_mail_smtp_password" {
  description = "SMTP mail password"
  type        = string
  sensitive   = true
  default     = ""
}

# Pusher secrets
variable "secret_pusher_app_id" {
  description = "Pusher application ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_pusher_app_key" {
  description = "Pusher application key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_pusher_app_secret" {
  description = "Pusher application secret"
  type        = string
  sensitive   = true
  default     = ""
}

# Firebase secrets
variable "secret_firebase_webhook_secret" {
  description = "Firebase webhook secret"
  type        = string
  sensitive   = true
  default     = ""
}

# Jitsi secrets
variable "secret_jitsi_jwt_app_secret" {
  description = "Jitsi JWT application secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_jitsi_sip_password" {
  description = "Jigasi SIP password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_jitsi_jicofo_password" {
  description = "Jicofo auth password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_jitsi_jvb_password" {
  description = "JVB auth password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_jitsi_jigasi_xmpp_password" {
  description = "Jigasi XMPP password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_jitsi_jigasi_transcriber_password" {
  description = "Jigasi transcriber password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_jitsi_jibri_recorder_password" {
  description = "Jibri recorder password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_jitsi_jibri_xmpp_password" {
  description = "Jibri XMPP password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_jitsi_turn_password" {
  description = "TURN server password"
  type        = string
  sensitive   = true
  default     = ""
}

# Transcription secrets
variable "secret_transcription_webhook_token" {
  description = "Transcription pipeline webhook token"
  type        = string
  sensitive   = true
  default     = ""
}

# GitHub secrets
variable "secret_github_token_main" {
  description = "GitHub personal access token (main)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "secret_github_token_wordpress" {
  description = "GitHub personal access token (wordpress)"
  type        = string
  sensitive   = true
  default     = ""
}

