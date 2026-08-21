# HelloID-Conn-SA-Full-Exchange-On-Premises-Mailcontact-Update

| :information_source: Information                                                                                                                                                                                                                                                                                                                                                          |
| :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| This repository contains the connector and configuration code only. The implementer is responsible for acquiring the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements. |

## Description

_HelloID-Conn-SA-Full-Exchange-On-Premises-Mailcontact-Update_ is a template designed for use with HelloID Service Automation (SA) Delegated Forms. It can be imported into HelloID and customized according to your requirements.

By using this delegated form, you can update an existing Exchange On-Premises mail contact with new attribute values. The following workflow is available:

1. Search for an existing mail contact by entering a name, alias, or email address
2. Select the mail contact you want to update from the search results
3. Modify the mail contact attributes (display name, first name, last name, initials, alias, external email address)
4. The form validates that the new display name, alias, and email address are unique (or already belong to the selected mail contact)
5. Optionally configure the mail contact visibility in the address list
6. The mail contact is updated with the new values in Exchange On-Premises
7. Comprehensive audit logs are generated for all operations

## Getting started

### Requirements

- **Exchange On-Premises Environment**:<br>
  An on-premises Exchange Server environment (2013, 2016, 2019, or newer) with PowerShell remote management enabled.

- **Exchange Administrative Credentials**:<br>
  An Exchange administrator account with sufficient permissions to manage mail contacts. The account must have permissions to run `Get-Recipient`, `Get-MailContact`, `Set-Contact`, and `Set-MailContact` cmdlets.

- **PowerShell Remoting**:<br>
  PowerShell remoting must be enabled on the Exchange server. The HelloID agent must be able to establish remote PowerShell sessions to the Exchange server using the configured connection URI.

- **Network Connectivity**:<br>
  The HelloID agent server must have network access to the Exchange PowerShell endpoint (typically `https://exchangeserver/powershell` or `http://exchangeserver/powershell`).

### Connection settings

The following user-defined variables are used by the connector.

| Setting               | Description                                    | Mandatory |
| --------------------- | ---------------------------------------------- | --------- |
| ExchangeConnectionUri | The PowerShell endpoint URI of Exchange server | Yes       |
| ExchangeAdminUsername | The username of Exchange administrator account | Yes       |
| ExchangeAdminPassword | The password of Exchange administrator account | Yes       |

## Remarks

### Authentication Method

The connector uses 'Default' authentication for establishing the Exchange PowerShell session. This authentication method supports various authentication mechanisms including Basic, Kerberos, and NTLM, depending on your Exchange server configuration.

### Session Security Options

The connector sets all security check parameters (`SkipCACheck`, `SkipCNCheck`, `SkipRevocationCheck`) to `$false` to ensure secure connections. If your environment uses self-signed certificates or has specific certificate requirements, you may need to adjust these settings in the datasource and task scripts.

### GUID-Based Identity Resolution

The connector uses the mailcontact GUID property for all update operations. This ensures accurate identification of the mail contact even if display names or email addresses change during the update process.

### Split Validation Datasources

Validation is performed by three separate datasources that check uniqueness for display name, alias, and email address independently. Each validation datasource verifies whether the value is:

- Unique and free to use
- Already in use by the selected mailcontact (which is acceptable for updates)
- In use by a different object (which blocks the update)

### Update Operations

The task performs mail contact updates in two distinct operations:

1. **Name attributes** are updated using `Set-Contact` (DisplayName, FirstName, LastName, Initials)
2. **Mail-specific attributes** are updated using `Set-MailContact` (Alias, ExternalEmailAddress, HiddenFromAddressListsEnabled)

This separation ensures that Active Directory attributes and Exchange mail attributes are properly synchronized.

### Command Import Optimization

The connector explicitly specifies which Exchange cmdlets to import during session creation. This reduces memory usage and improves performance by avoiding the import of unnecessary Exchange cmdlets. Only the required commands (`Get-Recipient`, `Get-MailContact`, `Set-Contact`, `Set-MailContact`) are imported.

## Development resources

### PowerShell Cmdlets

The following Exchange PowerShell cmdlets are used:

| Cmdlet          | Description                                    | Documentation                                                                                  |
| --------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Get-Recipient   | Retrieves recipients for validation and search | [Microsoft Docs](https://learn.microsoft.com/en-us/powershell/module/exchange/get-recipient)   |
| Get-MailContact | Retrieves mail contact details                 | [Microsoft Docs](https://learn.microsoft.com/en-us/powershell/module/exchange/get-mailcontact) |
| Set-Contact     | Updates Active Directory contact attributes    | [Microsoft Docs](https://learn.microsoft.com/en-us/powershell/module/exchange/set-contact)     |
| Set-MailContact | Updates Exchange mail contact attributes       | [Microsoft Docs](https://learn.microsoft.com/en-us/powershell/module/exchange/set-mailcontact) |

### API documentation

- [Connect to Exchange servers using remote PowerShell](https://learn.microsoft.com/en-us/powershell/exchange/connect-to-exchange-servers-using-remote-powershell)
- [Exchange PowerShell Module](https://learn.microsoft.com/en-us/powershell/exchange/exchange-management-shell)

## Getting help

> :bulb: **Tip:**  
> _For more information on Delegated Forms, please refer to our [documentation](https://docs.helloid.com/en/service-automation/delegated-forms.html) pages_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
