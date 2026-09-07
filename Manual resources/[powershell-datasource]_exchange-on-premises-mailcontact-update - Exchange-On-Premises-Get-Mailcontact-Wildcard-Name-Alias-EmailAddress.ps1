# Variables configured in form
$searchValue = $datasource.searchValue
if ($searchValue -eq "*") {
    $filter = "RecipientTypeDetails -eq 'MailContact'"
}
else {
    $filter = "RecipientTypeDetails -eq 'MailContact' -and (DisplayName -like '*$searchValue*' -or Alias -like '*$searchValue*' -or PrimarySmtpAddress -like '*$searchValue*')"
}

Write-Information $filter

# Global variables
# Outcommented as these are set from Global Variables
# $ExchangeConnectionUri = ""
# $ExchangeAdminUsername = ""
# $ExchangeAdminPassword = ""

# Fixed values
# Properties to select - Select only needed properties to limit memory usage and speed up processing
$propertiesToSelect = @(
    "Guid"
    , "DisplayName"
    , "FirstName"
    , "LastName"
    , "Initials"
    , "PrimarySMTPAddress"
    , "DistinguishedName"
    , "Alias"
    , "RecipientTypeDetails"
    , "HiddenFromAddressListsEnabled"
)

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# Set debug logging
$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

#region functions
#endregion functions

try{
    # Create credentials
    $actionMessage = "creating credentials object"
    
    $securePassword = ConvertTo-SecureString -String $ExchangeAdminPassword -AsPlainText -Force
    $credential = [System.Management.Automation.PSCredential]::new($ExchangeAdminUsername, $securePassword)

    # Connect to Exchange On-Premises
    # Docs: https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-servers-using-remote-powershell
    $actionMessage = "connecting to Exchange On-Premises using URI [$ExchangeConnectionUri]"

    $sessionOptionParams = @{
        SkipCACheck         = $false
        SkipCNCheck         = $false
        SkipRevocationCheck = $false
    }

    $sessionOption = New-PSSessionOption @sessionOptionParams

    $sessionParams = @{
        Authentication    = 'Default'
        ConfigurationName = 'Microsoft.Exchange'
        ConnectionUri     = $ExchangeConnectionUri
        Credential        = $credential
        SessionOption     = $sessionOption
        ErrorAction       = "Stop"
    }

    $exchangeSession = New-PSSession @sessionParams
    $null = Import-PSSession -Session $exchangeSession -DisableNameChecking -AllowClobber -CommandName "Get-Recipient" -ErrorAction Stop

    # Get Mailboxes
    # Docs: https://learn.microsoft.com/en-us/powershell/module/exchange/get-recipient
    $actionMessage = "querying mailcontacts that match filter [$($filter)]"
    
    $getMailcontactsParams = @{        
        Filter = $filter
        ResultSize = "Unlimited"
        ErrorAction = 'Stop'
    }
   
    $mailcontacts = Get-Recipient @getMailcontactsParams | Select-Object -Property $propertiesToSelect   
    Write-Information "Queried mailcontacts that match filter [$($filter)]. Result count: $(($mailcontacts | Measure-Object).Count)"

    # Sort and send results to HelloID
    $actionMessage = "sending results to HelloID"
    $mailcontacts | Sort-Object -Property DisplayName | ForEach-Object {
        Write-Output $_
    }
  
} catch {
    $ex = $PSItem
    if (-not [string]::IsNullOrEmpty($ex.Exception.Message)) {
        $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
        $auditMessage = "Error $($actionMessage). Error: $($ex.Exception.Message)"
    }
    else {
        $warningMessage = "Error at Line [$($ex.InvocationInfo.ScriptLineNumber)]: $($ex.InvocationInfo.Line). Error: $($ex.Exception)"
        $auditMessage = "Error $($actionMessage). Error: $($ex.Exception)"
    }
    Write-Warning $warningMessage
    Write-Error $auditMessage
    # exit # use when using multiple try/catch and the script must stop
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
        }
        catch {
            Write-Warning "Failed to disconnect from Exchange using URI [$ExchangeConnectionUri]. Error: $($_.Exception.Message)"
        }
    }
}

