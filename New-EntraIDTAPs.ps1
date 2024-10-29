<#
.SYNOPSIS
Creates and emails Temporary Access Passes (TAPs).

.DESCRIPTION
Creates and emails Temporary Access Passes to users in a CSV file

.PARAMETER
None

.EXAMPLE
None

.INPUTS
A csv file with 'Name', 'Username' and 'Email' columns

.OUTPUTS
A logfile

.NOTES
Author:        Patrick Horne
Creation Date: 27/10/24
Requires:       Microsoft.PowerShell.ConsoleGuiTools
Version:        An App registration in Azure AD with the following permissions:
                - UserAuthenticationMethod.ReadWrite.All
                - User.Read.All
                - Mail.Send

Change Log:
    V1.0:         Initial Development
#>

# Functions
function Get-OpenFileDialog {
    [CmdletBinding()]
    param (
        [string]
        $Directory = [Environment]::GetFolderPath('Desktop'),
        [string]
        $Filter = 'CSV (*.csv)| *.csv'
    )
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = [System.Windows.Forms.OpenFileDialog]::new()
    $openFileDialog.InitialDirectory = $Directory
    $openFileDialog.Filter = $Filter
    $openFileDialog.ShowDialog()
    $openFileDialog
}
function Import-ValidCSV {
    param (
        [parameter(Mandatory)]
        [ValidateScript({Test-Path $_ -type leaf})]
        [string] $inputFile,
        [string[]] $requiredColumns
    )
    $csvImport = Import-Csv -LiteralPath $inputFile
    $requiredColumns | ForEach-Object {
        if ($_ -notin $csvImport[0].psobject.properties.name) {
            throw "$inputFile is missing the $_ column"
        }
    }
    $csvImport
}
function WriteLog {
    param (
        [string]$LogString
    )
        $Stamp      = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
        $LogMessage = "$Stamp $LogString"
        Add-Content $LogFile -Value $LogMessage
}
function New-EntraIDTAP {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Userdata
    )
    $isDateValid = $false
    do {
        # Prompt to select date and time for TAP start.
        $Dates = for ($i = 0; $i -lt 30; $i++) { 
            (Get-Date).AddDays($i).ToString("yyyy-MM-dd") 
        }
        $Date = $Dates | Out-ConsoleGridView -Title 'Select Start Date' -OutputMode Single

        $Times = for ($i = 0; $i -lt 24; $i++) { 
            (Get-Date -Hour 0 -Minute 0).AddHours($i).ToString("HH:mm") 
        }
        $Time = $Times | Out-ConsoleGridView -Title 'Select Start Time' -OutputMode Single

        # Validate and format selected date and time.
        $StartDateTimeString = "$Date`T$Time`:00.000Z"
        $isDateValid = Test-DateTime -DateTimeString $StartDateTimeString
        if (-not $isDateValid) { Start-Sleep -Seconds 2 }
    } while (-not $isDateValid)

    # Select the duration of the Tap.
    $Durations = for ($i = 1; $i -lt 9; $i++) {
        $i
    }
    $Duration = ($Durations | Out-ConsoleGridView -Title 'Duration (hours valid)' -OutputMode Single) * 60
    # Select the multiuse option of the Tap (isUsableOnce).
    $Choices = @($true, $false)
    $Choice = $Choices | Out-ConsoleGridView -Title 'Is usable once' -OutputMode Single

    # Loop through each user and create a TAP.
    $Counter = 1
    foreach ($User in $Userdata) {
        $PercentComplete = [int]($Counter/($($Userdata.Count))*100)
        if ($null -ne $Host.UI.RawUI.WindowPosition) {
        Write-Progress -Id 1 -Activity "Creating $($Userdata.Count) TAPs" -Status "$PercentComplete% Complete"  -PercentComplete $PercentComplete
        }
        $Counter++
        Start-Sleep -Seconds 2
        $UserId = (Get-MgUser -Filter "userPrincipalName eq '$($User.username)'" | Select-Object -Property Id).Id
        if ($null -eq $UserId) {
            Write-Host "User $($User.username) not found in Entra ID."
            continue
        }
        $params = @{
            startDateTime     = $StartDateTime
            lifetimeInMinutes = $Duration
            isUsableOnce      = $Choice
        }

        $Tap = New-MgUserAuthenticationTemporaryAccessPassMethod -UserId $UserId -BodyParameter $params

        if ($null -eq $Tap) {
        Write-Host "Failed to create TAP for $($User.username)."
        WriteLog "Failed to create TAP for $($User.username)"
        continue
}

        If ($null -ne $Tap) {

            # Format the start date and time
            $day = $tap.StartDateTime.Day
            $month = $tap.StartDateTime.ToString("MMMM")
            $year = $tap.StartDateTime.Year

            $suffix = switch ($day) {
                { $_ -in 11..13 } { "th" }  # Special case for 11th, 12th, 13th
                { ($_ % 10) -eq 1 } { "st" }
                { ($_ % 10) -eq 2 } { "nd" }
                { ($_ % 10) -eq 3 } { "rd" }
                default { "th" }
            }

            $formattedDate = "$day$suffix of $month $year"

            # Construct the HTML body
            $Body = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Onboarding Information</title>
    <style>
        @media screen and (max-width: 600px) {
        .content {
            width: 100% !important;
            display: block !important;
            padding: 10px !important;
        }
        .header, .body, .footer {
        padding: 20px !important;
        }
        }
    </style>
</head>
<body style="font-family: 'Poppins', Arial, sans-serif">
    <table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
            <td align="center" style="padding: 20px;">
                <table class="content" width="600" border="0" cellspacing="0" cellpadding="0" style="border-collapse: collapse; border: 1px solid #cccccc;">
                    <!-- Header -->
                    <tr>
                        <td class="header" style="background-color: #345C72; padding: 40px; text-align: center; color: white; font-size: 24px;">
                            <strong>Welcome to Authentilab</strong> 
                            <p>Important Onboarding Information</p>
                        </td>
                    </tr>

                    <!-- Body -->
                    <tr>
                        <td class="body" style="padding: 40px; text-align: left; font-size: 16px; line-height: 1.6;">
                            Hello $($User.name),<br>
                            Your Temporary Access Pass (TAP) is:
                    <tr>
                        <td style="padding: 0px 40px 0px 40px; text-align: center;">
                            <!-- TAP Button -->
                            <table cellspacing="0" cellpadding="0" style="margin: auto;">
                                <tr>
                                    <td align="center" style="background-color: #345C72; padding: 10px 20px; border-radius: 5px;">
                                        <strong style="color: white;">$($tap.TemporaryAccessPass)</strong>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>            
                        </td>
                    </tr>
                    <tr>
                        <td class="body" style="padding: 40px; text-align: left; font-size: 16px; line-height: 1.6;">
                            This TAP is valid for $($tap.LifetimeInMinutes) minutes from $($tap.StartDateTime.ToString("HH:mm")) on $($tap.StartDateTime.DayOfWeek) the $formattedDate.
                            <p>Please follow the instructions provided previously to use this TAP to access your shift calendar and other important information on your device.</p>            
                        </td>
                    </tr>
                    <!-- Footer -->
                    <tr>
                        <td class="footer" style="background-color: #333333; padding: 40px; text-align: center; color: white; font-size: 14px;">
                            If you have any questions or need assistance, please contact the IT Service Desk on 0800 444 555
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
"@

            $emailParams = @{
                Importance   = "High"
                Subject      = "Your Temporary Access Pass"
                Body         = @{
                    ContentType = "HTML"
                    Content     = $Body
                }
                ToRecipients = @(
                    @{
                        EmailAddress = @{
                            Address = $User.email
                        }
                    }
                )
            }

            Send-MGUserMail -UserId $SenderId -Message $emailParams -saveToSentItems:$false
        }
        else {
            Write-Host "Failed to create TAP for $($User.username)."
        }
    }

}
function Test-DateTime {
    param ($DateTimeString)
    try {
        $DateTime = [datetime]::ParseExact($DateTimeString, "yyyy-MM-ddTHH:mm:ss.fffZ", $null)
        if ($DateTime -lt (Get-Date)) {
            Write-Host "The selected date and time are in the past." -ForegroundColor Red 
            return $false
        }
        return $true
    }
    catch {
        Write-Host "Invalid date/time format. Please enter a valid date and time." -ForegroundColor Red 
        return $false
    }
}

# Import configuration file
# Check for configuration file
$configPath = "$PSScriptRoot\config.ps1"

if (Test-Path $configPath) {
    . $configPath  # Load configuration file
} else {
    Write-Host "Configuration file not found at $configPath. Please ensure it exists." -ForegroundColor Red
    exit 1
}


# Start of script
# Try to create a log file and exit if it fails.
try {
    $logfilePath = "C:\temp\TAPCreationLog_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
    $null = $logfile = New-Item -Path $logfilePath -ItemType File -Force -ErrorAction Stop
    WriteLog "Script started at $(Get-Date) under user $($env:USERDOMAIN)\$($env:USERNAME) on system $($env:COMPUTERNAME)"
    Write-Host "Log file created at $logfilePath" -ForegroundColor Green
}
catch {
    Write-Host "Error creating or opening the log file: $_"
    exit
}
# Try to import the CSV file and exit if it fails.
Try {
    Write-Host "Select user input file" -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    WriteLog "Prompting for CSV"
    $CsvPath = Get-OpenFileDialog
    [Array]$Userdata = Import-ValidCSV -inputFile $CsvPath.FileName -requiredColumns 'Name', 'Username', 'Email'
}
Catch {
    Write-Host "CSV was not selected or did not have the required column name" -ForegroundColor Red
    WriteLog "CSV was not selected or did not have the required column name"
    exit
}       
# If its not already installed try to install required modules and exit if it fails.
if (!(Get-Module -ListAvailable -Name Microsoft.PowerShell.ConsoleGuiTools)) {
    try {
        Install-Module Microsoft.PowerShell.ConsoleGuiTools -Scope CurrentUser -Force -ErrorAction Stop
    }
    catch {
        Write-Host "The required modules could not be installed" -ForegroundColor Yellow
        WriteLog "The required modules could not be installed"
        exit
    }
}
# Try to connect to Graph and exit if it fails.
try {
    Connect-MgGraph -clientid $ClientId -tenantid $TenantId -certificatethumbprint $thumbprint -ErrorAction Stop
    
}
catch {
    Write-Host "Could not connect to Graph" -ForegroundColor Yellow
    WriteLog "Could not connect to Graph"
    exit
}

New-EntraIDTAP -Userdata $Userdata

Disconnect-MgGraph