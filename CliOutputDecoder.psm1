﻿#
# Module file for module "CLIOutputDecoder"
#
# Generated by: Christoph Rust, KrizKodez Tools and Components
#
# Generated on: 2022-12-01
#

# CliOutputDecoder private constants.
# !!!!   DO NOT CHANGE THIS DEFINITIONS   !!!!
New-Variable -Name CliOutputDecoderSuffix -Value '.json' -Option Constant
New-Variable -Name CliOutputDecoderModuleBase -Value "$PSScriptRoot\" -Option Constant
New-Variable -Name CliOutputBuiltinDecoders -Value "${CliOutputDecoderModuleBase}Decoder\" -Option Constant

# Load all private commands.
. $PSScriptRoot\Private\Test-CliDecoder.ps1

# Load all public commands.
. $PSScriptRoot\Public\ConvertFrom-CliOutput.ps1
. $PSScriptRoot\Public\Get-CliDecoder.ps1

# Define aliases.
New-Alias -Name to -Value ConvertFrom-CliOutput
New-Alias -Name Decoder -Value Get-CliDecoder
Export-ModuleMember -Alias *

# Export public functions.
Export-ModuleMember -Function *


