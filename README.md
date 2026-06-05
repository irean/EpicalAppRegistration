# Epical Assessment App Registration

This script creates a **read-only** app registration in your Entra ID tenant.  
It is used by Epical to perform a governance assessment of your Entra environment.  
No changes will be made to your tenant — this app can only read data.

---

## What the script does

1. Generates a self-signed certificate on your machine (no passwords or secrets are created)
2. Creates an app registration in your tenant with the certificate attached
3. Requests the following read-only permissions:

| Permission | What it allows Epical to read |
|---|---|
| `Directory.Read.All` | Users, groups, service principals, owners, members |
| `AuditLog.Read.All` | Sign-in logs, inactive accounts and apps |
| `Application.Read.All` | App registrations, credential expiry dates |
| `Policy.Read.All` | Conditional Access policies, entitlement policies |
| `LifecycleWorkflows.Read.All` | Lifecycle workflows, tasks, execution conditions |
| `EntitlementManagement.Read.All` | Access packages, entitlement management catalogs |
| `AccessReview.Read.All` | Access reviews, review history and decisions |

---

## Before you start

Make sure you have the following:

- PowerShell 7 or later (recommended — works on Windows, macOS, and Linux)
- The Microsoft Graph Authentication module installed
- A **Global Administrator** or **Application Administrator** account in your tenant

### Install the Microsoft Graph Authentication module (if not already installed)

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
```

### Connect to your tenant

```powershell
Connect-MgGraph -TenantId "yourtenant.onmicrosoft.com" -Scopes "Application.ReadWrite.All"
```

Sign in with a Global Administrator or Application Administrator account when prompted.

---

## Running the script

1. Open PowerShell
2. Navigate to the folder where you saved the script
3. Run the following command, replacing the tenant ID with your own:

```powershell
.\New-EpicalAssessmentApp.ps1 -TenantId "yourtenant.onmicrosoft.com"
```

The script will print the result when it finishes, including the Application ID and certificate thumbprint.

---

## After running the script — grant admin consent

The permissions the script requests are **application permissions**. These require an administrator to explicitly approve them before they take effect.

1. Go to the [Entra Portal](https://entra.microsoft.com)
2. Navigate to **Identity > Applications > App registrations**
3. Search for **Epical-Assessment-Reader** and open it
4. Click **API permissions** in the left menu
5. Click **Grant admin consent for \<your tenant name\>**
6. Confirm by clicking **Yes**

Without this step, Epical will not be able to connect.

---

## Share the following details with Epical

Once the script has run and admin consent has been granted, share these three values with Epical securely. We recommend using a tool that supports secure one-time sharing, for example [OneTimeSecret](https://onetimesecret.com/) or the secure sharing feature in your password manager (such as 1Password, Bitwarden, or similar). Avoid sending the values in plain text via email.

- **Application ID** (printed by the script)
- **Tenant ID** (your tenant ID)
- **Certificate thumbprint** (printed by the script)

Do **not** share the certificate file itself — Epical does not need it.  
The private key stays on your machine and is never sent anywhere.

---

## Removing access after the assessment

When the assessment is complete, you can remove Epical's access by deleting the app registration:

1. Go to the [Entra Portal](https://entra.microsoft.com)
2. Navigate to **Identity > Applications > App registrations**
3. Search for **Epical-Assessment-Reader**
4. Click **Delete** and confirm

This immediately revokes all access.

---

## Questions?

Contact your Epical representative if you have any questions about this script or the assessment process.
