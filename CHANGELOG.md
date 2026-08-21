# Changelog

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [2.0.0] - 2026-08-21

### Added

- Added separate datasource `Exchange-On-Premises-Check-DisplayName-Unique` for validating display name uniqueness
- Added separate datasource `Exchange-On-Premises-Check-Alias-Unique` for validating alias uniqueness
- Added separate datasource `Exchange-On-Premises-Check-EmailAddress-Unique` for validating email address uniqueness
- Added comprehensive audit logging with detailed success and error messages throughout all datasources and tasks
- Added `$actionMessage` variable for structured error tracking across all datasources
- Added finally blocks to ensure Exchange session cleanup in all datasources
- Added proper GUID-based identity resolution for mailcontact operations

### Changed

- Refactored validation logic from single combined datasource to three specialized validation datasources for better separation of concerns
- Improved datasource naming convention from `Exchange-mailcontact-update-*` to `exchange-on-premises-mailcontact-update - Exchange-On-Premises-*` for better clarity
- Enhanced security by changing session options: SkipCACheck, SkipCNCheck, and SkipRevocationCheck now set to `$false` instead of `$true`
- Refactored wildcard search datasource to use direct `Get-Recipient` cmdlet with filter instead of `Invoke-Command` for better performance
- Improved Exchange session management by explicitly specifying commands to import rather than importing all cmdlets
- Enhanced error handling structure with try-catch-finally blocks across all datasources and task
- Changed HiddenFromAddressListsEnabled parameter handling from string comparison to `[System.Convert]::ToBoolean()` for type safety
- Updated task to use splatted parameters with `@exchangeMailContactUpdateParams` for better code readability
- Modified task to perform updates in two distinct steps: name attributes first with `Set-Contact`, then mail-specific attributes with `Set-MailContact`
- Improved variable naming convention in task: changed `$DN`, `$Alias`, `$ExternalEmailAddress` to `$mailContact`, `$mailcontactAlias`, `$mailcontactMailaddress` for consistency
- Enhanced audit log entries with more descriptive action messages and proper target identifiers using GUID

### Fixed

- Corrected mailcontact identity resolution to use GUID instead of potentially ambiguous Identity property
- Fixed potential session leaks by adding proper session cleanup in finally blocks across all datasources
- Improved error message clarity by including line numbers and detailed exception information

### Removed

- Removed combined validation datasource `Exchange-mailcontact-update-check-names` in favor of specialized validation datasources
- Removed `Remove-EmptyValuesFromHashtable` function as it is no longer needed with improved parameter handling
- Removed `Resolve-HTTPError` function as error handling now uses structured try-catch blocks

## [1.0.0] - 2023-08-18

Initial release of HelloID-Conn-SA-Full-Exchange-On-Premises-Mailcontact-Update.

### Added

- Initial release for updating Exchange On-Premises Mail Contacts
- Datasource to search for mail contacts using wildcard search on name, alias, and email address
- Datasource to validate external email address availability
- Datasource to retrieve mail contact visibility settings
- Task to update mail contact attributes including name, alias, email address, and address list visibility
- Support for Exchange On-Premises connection using Kerberos authentication
- Basic audit logging for operations
