<#
.SYNOPSIS
    Generates secrets.tfvars from existing .env files for OCI Vault setup

.DESCRIPTION
    This script extracts secrets from your official-production .env files and
    generates a secrets.tfvars file that Terraform uses to populate the OCI Vault.

    The generated file should NEVER be committed to source control.
    Add it to .gitignore immediately after generation.

.EXAMPLE
    .\generate-secrets-tfvars.ps1

.NOTES
    Run this once before running terraform apply to populate the vault.
    After vault is populated, you can delete secrets.tfvars.
#>

param(
    [string]$EnvSourceDir = "$PSScriptRoot\..\official-production",
    [string]$OutputFile = "$PSScriptRoot\secrets.tfvars",
    [string]$Environment = "production",
    [string]$Project = "official"
)

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  OCI Vault Secrets Generator" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Load environment config to get GitHub tokens and other centralized secrets
$envConfigPath = Join-Path $PSScriptRoot "..\environment-config.ps1"
$envConfig = $null
if (Test-Path $envConfigPath) {
    Write-Host "`nLoading environment config from: $envConfigPath" -ForegroundColor Yellow
    try {
        $envConfig = & $envConfigPath -Environment $Environment -Project $Project
        Write-Host "  Environment config loaded successfully" -ForegroundColor Green
    } catch {
        Write-Host "  Warning: Could not load environment config: $_" -ForegroundColor Yellow
    }
}

# Helper function to read a value from an .env file
function Get-EnvValue {
    param(
        [string]$EnvFile,
        [string]$Key
    )

    if (-not (Test-Path $EnvFile)) {
        return ""
    }

    $content = Get-Content $EnvFile -Raw
    if ($content -match "(?m)^$Key=(.*)$") {
        $value = $matches[1].Trim()
        # Remove surrounding quotes if present
        if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") {
            $value = $matches[1]
        }
        return $value
    }
    return ""
}

# Helper function to escape value for Terraform
function Format-TerraformString {
    param([string]$Value)
    if ([string]::IsNullOrEmpty($Value)) {
        return '""'
    }
    # Escape backslashes for Terraform HCL format (one backslash becomes two)
    # Use [regex]::Escape alternative to avoid PowerShell double-processing
    $escaped = $Value.Replace('\', '\\').Replace('"', '\"')
    return "`"$escaped`""
}

Write-Host "`nReading secrets from .env files in: $EnvSourceDir" -ForegroundColor Yellow

# Define the .env files to read
$envFiles = @{
    openemr       = Join-Path $EnvSourceDir "openemr\.env"
    telehealth    = Join-Path $EnvSourceDir "telehealth\.env"
    jitsi         = Join-Path $EnvSourceDir "jitsi-docker\.env"
    transcription = Join-Path $EnvSourceDir "transcription-pipeline\.env"
}

# Collect all secrets
$secrets = @{}

# Database secrets
Write-Host "  Reading OpenEMR database password..." -ForegroundColor Gray
$secrets["secret_database_openemr_password"] = Get-EnvValue $envFiles.openemr "OPS_DB_PASSWORD"
if ([string]::IsNullOrEmpty($secrets["secret_database_openemr_password"])) {
    $secrets["secret_database_openemr_password"] = Get-EnvValue $envFiles.openemr "MYSQL_ROOT_PASSWORD"
}

Write-Host "  Reading Telehealth database password..." -ForegroundColor Gray
$secrets["secret_database_telehealth_password"] = Get-EnvValue $envFiles.telehealth "DB_PASSWORD"

# OpenEMR secrets
Write-Host "  Reading OpenEMR notification token..." -ForegroundColor Gray
$secrets["secret_openemr_notification_token"] = Get-EnvValue $envFiles.openemr "NOTIFICATION_TOKEN"

# Telehealth secrets
Write-Host "  Reading Telehealth APP_KEY..." -ForegroundColor Gray
$secrets["secret_telehealth_app_key"] = Get-EnvValue $envFiles.telehealth "APP_KEY"

Write-Host "  Reading Telehealth notification token..." -ForegroundColor Gray
$secrets["secret_telehealth_notification_token"] = Get-EnvValue $envFiles.telehealth "NOTIFICATION_TOKEN"

Write-Host "  Reading Telehealth webhook secret..." -ForegroundColor Gray
$secrets["secret_telehealth_webhook_secret"] = Get-EnvValue $envFiles.telehealth "WEBHOOK_SECRET"

Write-Host "  Reading Telehealth transcription token..." -ForegroundColor Gray
$secrets["secret_telehealth_transcription_token"] = Get-EnvValue $envFiles.telehealth "TRANSCRIPTION_NOTIFICATION_TOKEN"

Write-Host "  Reading Telehealth Redis password..." -ForegroundColor Gray
$secrets["secret_telehealth_redis_password"] = Get-EnvValue $envFiles.telehealth "REDIS_PASSWORD"

# Mail secrets
Write-Host "  Reading SMTP password..." -ForegroundColor Gray
$secrets["secret_mail_smtp_password"] = Get-EnvValue $envFiles.telehealth "MAIL_PASSWORD"

# Pusher secrets
Write-Host "  Reading Pusher credentials..." -ForegroundColor Gray
$secrets["secret_pusher_app_id"] = Get-EnvValue $envFiles.telehealth "PUSHER_APP_ID"
$secrets["secret_pusher_app_key"] = Get-EnvValue $envFiles.telehealth "PUSHER_APP_KEY"
$secrets["secret_pusher_app_secret"] = Get-EnvValue $envFiles.telehealth "PUSHER_APP_SECRET"

# Firebase secrets
Write-Host "  Reading Firebase webhook secret..." -ForegroundColor Gray
$secrets["secret_firebase_webhook_secret"] = Get-EnvValue $envFiles.telehealth "FIREBASE_WEBHOOK_SECRET"
if ([string]::IsNullOrEmpty($secrets["secret_firebase_webhook_secret"])) {
    $secrets["secret_firebase_webhook_secret"] = Get-EnvValue $envFiles.openemr "FIREBASE_WEBHOOK_SECRET"
}

# Jitsi secrets
Write-Host "  Reading Jitsi JWT secret..." -ForegroundColor Gray
$secrets["secret_jitsi_jwt_app_secret"] = Get-EnvValue $envFiles.jitsi "JWT_APP_SECRET"

Write-Host "  Reading Jitsi SIP password..." -ForegroundColor Gray
$secrets["secret_jitsi_sip_password"] = Get-EnvValue $envFiles.jitsi "JIGASI_SIP_PASSWORD"

Write-Host "  Reading Jitsi component passwords..." -ForegroundColor Gray
$secrets["secret_jitsi_jicofo_password"] = Get-EnvValue $envFiles.jitsi "JICOFO_AUTH_PASSWORD"
$secrets["secret_jitsi_jvb_password"] = Get-EnvValue $envFiles.jitsi "JVB_AUTH_PASSWORD"
$secrets["secret_jitsi_jigasi_xmpp_password"] = Get-EnvValue $envFiles.jitsi "JIGASI_XMPP_PASSWORD"
$secrets["secret_jitsi_jigasi_transcriber_password"] = Get-EnvValue $envFiles.jitsi "JIGASI_TRANSCRIBER_PASSWORD"
$secrets["secret_jitsi_jibri_recorder_password"] = Get-EnvValue $envFiles.jitsi "JIBRI_RECORDER_PASSWORD"
$secrets["secret_jitsi_jibri_xmpp_password"] = Get-EnvValue $envFiles.jitsi "JIBRI_XMPP_PASSWORD"
$secrets["secret_jitsi_turn_password"] = Get-EnvValue $envFiles.jitsi "TURN_PASSWORD"

# Transcription secrets
Write-Host "  Reading Transcription webhook token..." -ForegroundColor Gray
$secrets["secret_transcription_webhook_token"] = Get-EnvValue $envFiles.transcription "WEBHOOK_TOKEN"

# GitHub tokens - read from environment-config.ps1
Write-Host "  Reading GitHub tokens from environment config..." -ForegroundColor Gray
if ($envConfig -and $envConfig.Secrets -and $envConfig.Secrets.github) {
    $secrets["secret_github_token_main"] = $envConfig.Secrets.github.tokenMain
    $secrets["secret_github_token_wordpress"] = $envConfig.Secrets.github.tokenWordpress
    if (-not [string]::IsNullOrEmpty($secrets["secret_github_token_main"])) {
        Write-Host "    GitHub token (main) loaded from environment-config.ps1" -ForegroundColor Green
    }
    if (-not [string]::IsNullOrEmpty($secrets["secret_github_token_wordpress"])) {
        Write-Host "    GitHub token (wordpress) loaded from environment-config.ps1" -ForegroundColor Green
    }
} else {
    Write-Host "    GitHub tokens not found in environment-config.ps1" -ForegroundColor Yellow
    Write-Host "    Add them to environment-config.ps1 in the \$secrets.github section" -ForegroundColor Yellow
    $secrets["secret_github_token_main"] = ""
    $secrets["secret_github_token_wordpress"] = ""
}

# Generate the secrets.tfvars file
Write-Host "`nGenerating $OutputFile..." -ForegroundColor Yellow

$tfvarsContent = @"
# =============================================================================
# OCI Vault Secrets - AUTO-GENERATED
# =============================================================================
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Source: $EnvSourceDir
#
# WARNING: This file contains sensitive secrets!
# - DO NOT commit to source control
# - Add to .gitignore immediately
# - Delete after running terraform apply
# =============================================================================

# OCI Authentication (from environment-config.ps1)
tenancy_ocid               = $(Format-TerraformString $envConfig.OCI.tenancyOcid)
user_ocid                  = $(Format-TerraformString $envConfig.OCI.userOcid)
oracle_api_key_fingerprint = $(Format-TerraformString $envConfig.OCI.apiKeyFingerprint)
oracle_api_private_key_path = $(Format-TerraformString $envConfig.OCI.apiPrivateKeyPath)
region                     = $(Format-TerraformString $envConfig.OCI.region)
availability_domain_number = $(Format-TerraformString $envConfig.OCI.availabilityDomain)
ssh_public_key             = $(Format-TerraformString $envConfig.OCI.sshPublicKey)
ssh_private_key_path       = $(Format-TerraformString $envConfig.OCI.sshPrivateKeyPath)

# Database secrets
secret_database_openemr_password    = $(Format-TerraformString $secrets["secret_database_openemr_password"])
secret_database_telehealth_password = $(Format-TerraformString $secrets["secret_database_telehealth_password"])

# OpenEMR secrets
secret_openemr_notification_token = $(Format-TerraformString $secrets["secret_openemr_notification_token"])

# Telehealth secrets
secret_telehealth_app_key             = $(Format-TerraformString $secrets["secret_telehealth_app_key"])
secret_telehealth_notification_token  = $(Format-TerraformString $secrets["secret_telehealth_notification_token"])
secret_telehealth_webhook_secret      = $(Format-TerraformString $secrets["secret_telehealth_webhook_secret"])
secret_telehealth_transcription_token = $(Format-TerraformString $secrets["secret_telehealth_transcription_token"])
secret_telehealth_redis_password      = $(Format-TerraformString $secrets["secret_telehealth_redis_password"])

# Mail secrets
secret_mail_smtp_password = $(Format-TerraformString $secrets["secret_mail_smtp_password"])

# Pusher secrets
secret_pusher_app_id     = $(Format-TerraformString $secrets["secret_pusher_app_id"])
secret_pusher_app_key    = $(Format-TerraformString $secrets["secret_pusher_app_key"])
secret_pusher_app_secret = $(Format-TerraformString $secrets["secret_pusher_app_secret"])

# Firebase secrets
secret_firebase_webhook_secret = $(Format-TerraformString $secrets["secret_firebase_webhook_secret"])

# Jitsi secrets
secret_jitsi_jwt_app_secret           = $(Format-TerraformString $secrets["secret_jitsi_jwt_app_secret"])
secret_jitsi_sip_password             = $(Format-TerraformString $secrets["secret_jitsi_sip_password"])
secret_jitsi_jicofo_password          = $(Format-TerraformString $secrets["secret_jitsi_jicofo_password"])
secret_jitsi_jvb_password             = $(Format-TerraformString $secrets["secret_jitsi_jvb_password"])
secret_jitsi_jigasi_xmpp_password     = $(Format-TerraformString $secrets["secret_jitsi_jigasi_xmpp_password"])
secret_jitsi_jigasi_transcriber_password = $(Format-TerraformString $secrets["secret_jitsi_jigasi_transcriber_password"])
secret_jitsi_jibri_recorder_password  = $(Format-TerraformString $secrets["secret_jitsi_jibri_recorder_password"])
secret_jitsi_jibri_xmpp_password      = $(Format-TerraformString $secrets["secret_jitsi_jibri_xmpp_password"])
secret_jitsi_turn_password            = $(Format-TerraformString $secrets["secret_jitsi_turn_password"])

# Transcription secrets
secret_transcription_webhook_token = $(Format-TerraformString $secrets["secret_transcription_webhook_token"])

# GitHub secrets - loaded from environment-config.ps1
# If empty, add tokens to environment-config.ps1 in the `$secrets.github section
secret_github_token_main      = $(Format-TerraformString $secrets["secret_github_token_main"])
secret_github_token_wordpress = $(Format-TerraformString $secrets["secret_github_token_wordpress"])
"@

# Write without BOM (UTF8 in PowerShell 5.x adds BOM, so use .NET method)
[System.IO.File]::WriteAllText($OutputFile, $tfvarsContent, [System.Text.UTF8Encoding]::new($false))

# Count found vs missing secrets
$found = ($secrets.Values | Where-Object { -not [string]::IsNullOrEmpty($_) }).Count
$missing = ($secrets.Values | Where-Object { [string]::IsNullOrEmpty($_) }).Count

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "  Generation Complete!" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Output: $OutputFile" -ForegroundColor Green
Write-Host "  Secrets found: $found" -ForegroundColor Green
Write-Host "  Secrets missing: $missing" -ForegroundColor $(if ($missing -gt 0) { "Yellow" } else { "Green" })

if ($missing -gt 0) {
    Write-Host "`nMissing secrets (empty values):" -ForegroundColor Yellow
    foreach ($key in $secrets.Keys | Sort-Object) {
        if ([string]::IsNullOrEmpty($secrets[$key])) {
            Write-Host "  - $key" -ForegroundColor Yellow
        }
    }
}

Write-Host "`nNEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. If GitHub tokens are missing:" -ForegroundColor White
Write-Host "   Edit: ..\environment-config.ps1" -ForegroundColor Gray
Write-Host "   Find the `$secrets.github section and add your tokens" -ForegroundColor Gray
Write-Host "   Then re-run this script" -ForegroundColor Gray
Write-Host "2. Review $OutputFile for any other missing values" -ForegroundColor White
Write-Host "3. Run: terraform init (if first time)" -ForegroundColor White
Write-Host "4. Run: terraform apply -var-file=secrets.tfvars" -ForegroundColor White
Write-Host "5. After vault is created, DELETE secrets.tfvars" -ForegroundColor White
