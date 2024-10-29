# Temporary Access Pass (TAP) Creation Script

## Overview

This PowerShell script is designed to automate the creation and distribution of Temporary Access Passes (TAPs) for users specified in a CSV file. TAPs are useful for enabling temporary, restricted access to resources and can be sent to users via email as part of an onboarding process.

## Prerequisites

- ** An Entra ID App registration with the following Graph API permissions (protected by Certificate Authentication)
  - `UserAuthenticationMethod.ReadWrite.All`
  - `User.Read.All`
  - `Mail.Send`
- **CSV file**: The script requires a CSV file with the following columns:
  - `Name`: Name of the user.
  - `Username`: Username of the user (typically the UPN in Entra ID).
  - `Email`: Email address where the TAP will be sent. (could be a manager, could be the new hires private email address)
- **Config file**: `config.ps1` containing the following variables:
  - `$ClientId`: The client ID of the Entra ID app registration.
  - `$TenantId`: The tenant ID of the Entra ID tenant.
  - `$thumbprint`: Thumbprint of the certificate used for authentication.

- **Modules**: The following PowerShell modules are required:
  - `Microsoft.Graph.Users`
  - `Microsoft.Graph.Authentication`
  - `Microsoft.Graph.Mail`
  - `Microsoft.Graph.Identity.SignIns`
  - `Microsoft.PowerShell.ConsoleGuiTools`
  - `Microsoft.Graph.Users.Actions`
  The script installs any missing modules automatically.

## Required Permissions

The Azure AD app registration must have the following API permissions:

- `UserAuthenticationMethod.ReadWrite.All`
- `User.Read.All`
- `Mail.Send`

## Installation

1. Ensure the `config.ps1` file is located in the same directory as the script.
2. Install the required PowerShell modules listed above if they aren't automatically installed.
3. Install the certificate required for authenticating to the Entra ID App.

## Usage

1. Run the script in PowerShell.
2. When prompted, select the CSV file containing user details.
3. Follow the on-screen prompts to set the TAP start date, start time, duration, and usability options.
4. The script will log activity to a file in `C:\temp\` with a unique name based on the current date and time.

## Example

```powershell
.\Create-TAPs.ps1
