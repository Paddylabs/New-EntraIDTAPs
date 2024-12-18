# Temporary Access Pass (TAP) Creation Script

![Example Email](image.png)

## Overview

This PowerShell script is designed to automate the creation and distribution via email of Temporary Access Passes (TAPs) for users specified in a CSV file. TAPs are a time-limited, passcode-based authentication method that allows users to securely access their accounts and enroll other authentication methods, typically used during onboarding or recovery scenarios.

This script allows you to select a start date / time and duration for the TAPs and delivers them to the end users in a responsive HTML email with the details of the TAP
such as when and how long it is valid for.

## Prerequisites

- **An Entra ID App**: The script requires an app registration with the following Graph API permissions (protected by Certificate Authentication)
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

The script attempts to install any missing modules automatically.

## Installation

1. Ensure you have created and configured an Entra ID App registration with the required Graph API permissions
2. Ensure the `config.ps1` file is located in the same directory as the script.
3. Install the required PowerShell modules listed above if they aren't automatically installed.
4. Install the certificate required for authenticating to the Entra ID App.

## Usage

1. Run the script in PowerShell.
2. When prompted, select the CSV file containing user details.
3. Follow the on-screen prompts to set the TAP start date, start time, duration, and usability options.
4. The script will log activity to a file in `C:\temp\` with a unique name based on the current date and time.

## Example

```powershell
.\Create-TAPs.ps1
```

## Further thoughts on security

The certificate is required on the machine that runs the script but you could further lock this down by using a
Conditional Access policy to ensure the Entra ID App can only be accessed from a single IP address or machine.

You could also use an Application Access policy in EOL to ensure the App can only send from one mailbox.

## Disclaimer

This script and any content is offered "as is" with no warranty. While this script was tested and working in my environment, it is vital that you test it in a test environment before using in your production environment. I am not responsible for any outcome that arises from you using these scripts.
