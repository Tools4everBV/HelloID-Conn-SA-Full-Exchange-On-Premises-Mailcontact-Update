# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

# Variables configured in form
$mailContact = $form.selectedcontact
$mailcontactDisplayName = $form.displayname
$mailcontactMailaddress = $form.externalEmailAddress
$mailcontactAlias = $form.alias
$mailcontactFirstName = $form.firstname
$mailcontactInitials = $form.initials
$mailcontactLastName = $form.lastname
$blnHiddenFromAddressList = [System.Convert]::ToBoolean($form.hidefromaddresslist)

# Global variables
# Outcommented as these are set from Global Variables
# $ExchangeConnectionUri = ""
# $ExchangeAdminUsername = ""
# $ExchangeAdminPassword = ""
# $$ADMailContactsOU = ""

# Fixed values
$commands = @(
    "Get-MailContact"
    , "Set-MailContact"
    , "Set-Contact"
)

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# Set debug logging
$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

# Update Mail Contact
try {
     # Create credentials
    $actionMessage = "creating credentials object"
    
    $securePassword = ConvertTo-SecureString -String $ExchangeAdminPassword -AsPlainText -Force
    $credential = [System.Management.Automation.PSCredential]::new($ExchangeAdminUsername, $securePassword)
    
    Write-Verbose "Created credentials for user [$ExchangeAdminUsername]"

    # Connect to Exchange On-Premises
    # Docs: https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-servers-using-remote-powershell
    $actionMessage = "connecting to Exchange On-Premises"

    $sessionOptionParams = @{
        SkipCACheck         = $false
        SkipCNCheck         = $false
        SkipRevocationCheck = $false
    }

    $sessionOption = New-PSSessionOption @sessionOptionParams

    $sessionParams = @{
        Authentication    = 'Default'
        ConfigurationName = 'Microsoft.Exchange'
        Credential        = $credential
        ConnectionUri     = $ExchangeConnectionUri
        SessionOption     = $sessionOption
        ErrorAction       = "Stop"
    }

    $exchangeSession = New-PSSession @sessionParams
    $null = Import-PSSession -Session $exchangeSession -DisableNameChecking -AllowClobber -CommandName $commands -ErrorAction Stop

    # Send initial audit log
    $Log = @{
        Action            = "CreateAccount" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premises" # optional (free format text) 
        Message           = "Successfully connected to Exchange using URI [$ExchangeConnectionUri]" # required (free format text) 
        IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $ExchangeConnectionUri # optional (free format text) 
        TargetIdentifier  = $([string]$exchangeSession.InstanceId) # optional (free format text) 
    }
    Write-Information -Tags "Audit" -MessageData $log
    
    Write-Verbose "Updating mail contact '$($mailContact.DisplayName)' with ExternalEmailAddress '$($mailContact.PrimarySmtpAddress)'"

    $exchangeMailContactUpdateParams = @{
        Identity             = $($mailContact.Guid)
        Name                 = $mailcontactDisplayName
        DisplayName          = $mailcontactDisplayName
        FirstName            = $mailcontactFirstName
        Initials             = $mailcontactInitials
        LastName             = $mailcontactLastName
        ErrorAction          = 'Stop'
    }

    $actionMessage = 'updating Exchange On-Premises mailcontact name attributes'
    $null = Set-Contact @exchangeMailContactUpdateParams

    Write-Information "Successfully updated mail contact name attributes with the following parameters: $($exchangeMailContactUpdateParams|ConvertTo-Json)"
    $Log = @{
        Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premise" # optional (free format text) 
        Message           = "Successfully updated mail contact name attributes with the following parameters: $($exchangeMailContactUpdateParams|ConvertTo-Json)" # required (free format text) 
        IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $mailcontactDisplayName # optional (free format text) 
        TargetIdentifier  = $($mailContact.Guid) # optional (free format text) 
    }
    #send result back
    Write-Information -Tags "Audit" -MessageData $log  

    $exchangeMailContactUpdateParams = @{
        Identity             = $($mailContact.Guid)
        Alias                = $mailcontactAlias
        ExternalEmailAddress = $mailcontactMailaddress
        HiddenFromAddressListsEnabled   = $blnHiddenFromAddressList
        ErrorAction          = 'Stop'
    }
    
    $actionMessage = 'updating Exchange On-Premises mailcontact mail-specific attributes'
    $null = Set-MailContact @exchangeMailContactUpdateParams

    Write-Information "Successfully updated mail contact mail-specific attributes with the following parameters: $($exchangeMailContactUpdateParams|ConvertTo-Json)"
    $Log = @{
        Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premise" # optional (free format text) 
        Message           = "Successfully updated mail contact mail-specific attributes with the following parameters: $($exchangeMailContactUpdateParams|ConvertTo-Json)" # required (free format text) 
        IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $mailcontactDisplayName # optional (free format text) 
        TargetIdentifier  = $($mailContact.Guid) # optional (free format text) 
    }
    #send result back
    Write-Information -Tags "Audit" -MessageData $log    
}
catch {
    $ex = $PSItem
    if (-not [string]::IsNullOrEmpty($ex.Exception.Message)) {
        $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
        $auditMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
    }
    else {
        $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception)"
        $auditMessage = "Error $($actionMessage). Error: $($ex.Exception)"
    }

    # Send error audit log to HelloID
    $Log = @{
        Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
        System            = "Exchange On-Premises" # optional (free format text) 
        Message           = $auditMessage # required (free format text) 
        IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $mailbox.DisplayName # optional (free format text) 
        TargetIdentifier  = $mailbox.PrimarySmtpAddress # optional (free format text) 
    }
    
    Write-Information -Tags "Audit" -MessageData $log
    Write-Warning $warningMessage
    Write-Error $auditMessage
}
finally {
    # Disconnect from Exchange
    # Docs: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/remove-pssession
    if ($null -ne $exchangeSession) {
        try {
            $deleteExchangeSessionSplatParams = @{
                Session     = $exchangeSession
                Confirm     = $false
                ErrorAction = "Stop"
            }
            $null = Remove-PSSession @deleteExchangeSessionSplatParams

            # Send disconnect audit log
            $Log = @{
                Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
                System            = "Exchange On-Premises" # optional (free format text) 
                Message           = "Successfully disconnected from Exchange using URI [$ExchangeConnectionUri]" # required (free format text) 
                IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
                TargetDisplayName = $ExchangeConnectionUri # optional (free format text) 
                TargetIdentifier  = $([string]$exchangeSession.InstanceId) # optional (free format text) 
            }
            Write-Information -Tags "Audit" -MessageData $log
        }
        catch {
            Write-Warning "Failed to disconnect from Exchange using URI [$ExchangeConnectionUri]. Error: $($_.Exception.Message)"
        }
    }
}
