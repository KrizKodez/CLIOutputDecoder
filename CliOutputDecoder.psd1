﻿#
# Module manifest for module "CLIOutputDecoder"
#
# Generated by: Christoph Rust, KrizKodez Tools and Components
#
# Generated on: 2022-12-01
#

@{

# Script module or binary module file associated with this manifest
RootModule = 'CLIOutputDecoder.psm1'

# Version number of this module
ModuleVersion = '0.3.0'

# ID used to uniquely identify this module
GUID = 'a7893352-edd1-435f-a0d7-9a227650bd47'

# Author of this module
Author = 'Christoph Rust'

# Company or vendor of this module
CompanyName = 'KrizKodez, Tools and Components.'

# Copyright statement for this module
Copyright = '(c) 2022 KrizKodez, Tools and Components.'

# Description of the functionality provided by this module
Description = 'Parsing text output of CLI commands or other text sources.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Name of the Windows PowerShell host required by this module
PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
PowerShellHostVersion = '3.0'

# Minimum version of Microsoft .NET Framework required by this module
DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module
ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @('CliOutputDecoder.format.ps1xml')

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @()

# Functions to export from this module
FunctionsToExport = @('ConvertFrom-CliOutput',
                      'Get-CliDecoder')

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = @('ConvertFrom-CliOutput.ps1',
             'Get-CliDecoder.ps1',
             'Test-CliDecoder.ps1',
             'ComputerPolicy.json',
             'GetPackageInfo.json',
             'GetPackages.json',
             'nslookupDCIPs.json',
             'nslookupDCs.json',
             'QueryDuplicateSPN.json',
             'GPOData.json',
             'GPOLink.json')

# Private data to pass to the module specified in RootModule/ModuleToProcess
# PrivateData = ''

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
