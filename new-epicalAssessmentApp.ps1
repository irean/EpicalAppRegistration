[CmdletBinding()]
param(
    [string]$DisplayName = "Epical2-Assessment-Reader",
    [string]$Description = "Read-only assessment application deployed by Epical for Entra governance review",
    [string]$TenantId = "delusionaldev.onmicrosoft.com",
    [string]$CertName = "Epical-Assessment-Cert",
    [int]$CertValidityYears = 2
)

# Requires: Microsoft.Graph.Authentication module only
# Install-Module Microsoft.Graph.Authentication -Scope CurrentUser

# ─────────────────────────────────────────────
# 1. Generate a self-signed certificate
# ─────────────────────────────────────────────
Write-Host "Generating self-signed certificate..." -ForegroundColor Cyan

$cert = New-SelfSignedCertificate `
    -Subject "CN=$CertName" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeyExportPolicy Exportable `
    -KeySpec Signature `
    -KeyLength 2048 `
    -HashAlgorithm SHA256 `
    -NotAfter (Get-Date).AddYears($CertValidityYears)

# Export the public key (.cer) so it can be uploaded to the app registration
$certPath = "$env:TEMP\$CertName.cer"
Export-Certificate -Cert $cert -FilePath $certPath | Out-Null

# Encode the public key as Base64 for the Graph API call
$certBytes = [System.IO.File]::ReadAllBytes($certPath)
$certBase64 = [System.Convert]::ToBase64String($certBytes)

Write-Host "Certificate created. Thumbprint: $($cert.Thumbprint)" -ForegroundColor Green

# ─────────────────────────────────────────────
# 2. Create the app registration
#    Scopes (application permissions):
#      Directory.Read.All          - users, groups, SPNs, owners, members
#      AuditLog.Read.All           - sign-in logs, inactivity detection
#      Application.Read.All        - app registrations, credential expiry
#      Policy.Read.All             - Conditional Access, entitlement policies
#      LifecycleWorkflows.Read.All - lifecycle workflows, tasks, execution conditions
#      IdentityGovernance.Read.All - access packages, entitlement management, access reviews
# ─────────────────────────────────────────────
Write-Host "Creating app registration..." -ForegroundColor Cyan

$body = ConvertTo-Json -Depth 20 @{
    displayName            = $DisplayName
    description            = $Description
    signInAudience         = "AzureADMyOrg"
    api                    = @{}
    keyCredentials         = @(
        @{
            type        = "AsymmetricX509Cert"
            usage       = "Verify"
            displayName = $CertName
            key         = $certBase64
        }
    )
    requiredResourceAccess = @(
        @{
            resourceAppId  = "00000003-0000-0000-c000-000000000000"  # Microsoft Graph
            resourceAccess = @(
                @{ id = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"; type = "Role" },  # Directory.Read.All
                @{ id = "b0afded3-3588-46d8-8b3d-9842eff778da"; type = "Role" },  # AuditLog.Read.All
                @{ id = "9a5d68dd-52b0-4cc2-bd40-abcf44ac3a30"; type = "Role" },  # Application.Read.All
                @{ id = "246dd0d5-5bd0-4def-940b-0421030a5b68"; type = "Role" },  # Policy.Read.All
                @{ id = "7c67316a-232a-4b84-be22-cea2c0906404"; type = "Role" },  # LifecycleWorkflows.Read.All
                @{ id = "c74fd47d-ed3c-45c3-9a9e-b8676de685d2"; type = "Role" },  # EntitlementManagement.Read.All 
                @{ id = "d07a8cc0-3d51-4b77-b3b0-32704d1f69fa"; type = "Role" }   # AccessReview.Read.All
            )
        }
    )
}

$app = Invoke-MgGraphRequest -Method POST -ContentType "application/json" -Body $body -Uri "https://graph.microsoft.com/beta/applications"

Write-Host "App registration created. Application ID: $($app.appId)" -ForegroundColor Green

# ─────────────────────────────────────────────
# 3. Output - save everything needed for Epical
# ─────────────────────────────────────────────
$results = [PSCustomObject]@{
    DisplayName    = $app.displayName
    ApplicationID  = $app.appId
    TenantID       = $TenantId
    CertThumbprint = $cert.Thumbprint
    CertExpiry     = $cert.NotAfter.ToString("yyyy-MM-dd")
    CertPath       = $certPath
    ConnectCommand = "Connect-MgGraph -ClientId '$($app.appId)' -TenantId '$TenantId' -CertificateThumbprint '$($cert.Thumbprint)'"
}

Write-Host "`n─────────────────────────────────────────" -ForegroundColor Yellow
Write-Host " IMPORTANT - next steps" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────" -ForegroundColor Yellow
Write-Host "1. Go to Entra Portal > App registrations > $DisplayName"
Write-Host "2. Click 'API permissions' and then 'Grant admin consent for <your tenant>'"
Write-Host "3. Share the details below with Epical securely"
Write-Host "─────────────────────────────────────────`n" -ForegroundColor Yellow

$results | Format-List