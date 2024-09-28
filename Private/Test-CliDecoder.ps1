<#PSScriptInfo

.VERSION 1.0.0

.GUID 2861883C-DBBC-4687-9E0C-1F5196431484

.AUTHOR Christoph Rust

.COMPANYNAME KrizKodez, Tools and Components.

.COPYRIGHT (c) 2022 KrizKodez, Tools and Components.

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES
   
.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
    2022-12-01, 0.1.0, Christoph Rust, Initial release. 
    2023-01-18, 0.1.1, Christoph Rust, Changed Decoder property 'Command' to 'Source'.
    2023-02-26, 0.1.2, Christoph Rust, Changed check of Decoder property 'Type'.
    2024-01-14, 1.0.0, Christoph Rust, First production release.
#>

<#
.Synopsis
    Test CLI output Decoder.         

.Description
    The function tests if a Decoder has the mandatory set of properties and if
    they are of the correct type and are well formed.
    
.Inputs
    PSCustomObject
    A PSCustomObject Decoder to be tested.
        
    You cannot pipe input to this cmdlet.

.Outputs
    PSCustomObject
    The result objects contains the test result and an error reason.
 
.Notes
    This funtion is private only.
 
.Link
 
.Example
  
.Parameter InputObject
    A PSCustomObject Decoder to be tested.

.Parameter Script
    In this mode only a subset of properties in the Decoder will be tested.

#>
function Test-CliDecoder
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [pscustomobject]$InputObject,

        [switch]$Script
    )

    # Prepare the Result object.
    $Result = [PSCustomObject]@{IsOK = $true; ErrorMessage = "OK"}

    # Collect all properties of the submitted Decoder to check them.
    $ResultProperties = @()     # Decoder properties which defining output result properties (PSCustomObject).
    $NonResultProperties = @{}  # Decoder properties which describing the decoder and its behavior (NOT PSCustomObject).
    foreach ($Property in $InputObject.psobject.Properties)
    {
        if ($Property.TypeNameOfValue -match 'PSCustomObject') { $ResultProperties += $Property.Name }
        else                                                   { $NonResultProperties.Add($Property.Name,$Property) }
    }

    # Define a list of properties which must exist in the Decoder.
    # In 'Script' mode we have only a subset of properties to check.
    if ($Script) { $MandatoryProperties = @('Skip','Separator') }
    else         { $MandatoryProperties = @('Description','Source','Parameter','Skip','Separator') }
    
    # Check if the mandatory properties are existing in the submitted Decoder.
    foreach ($Name in $MandatoryProperties)
    {
        if ($NonResultProperties.Keys -contains $Name) { Continue }
        $Result.IsOK = $false
        $Result.ErrorMessage = "Property ($Name) is mandatory."
        Write-Output $Result
        return
    }
    
    # Some properties must have certain types.
    if ($NonResultProperties['Skip'].TypeNameOfValue -ne 'System.Int32')
    {
        $Result.IsOK = $false
        $Result.ErrorMessage = "Property (Skip) must be an integer."
        Write-Output $Result
        return
    }
    if ($NonResultProperties['Separator'].TypeNameOfValue -ne 'System.Object[]')
    {
        $Result.IsOK = $false
        $Result.ErrorMessage = "Property (Separator) must be an array."
        Write-Output $Result
        return
    }

    # Check if we have any result properties in the Decoder.
    if (-not $ResultProperties.Count)
    {
        $Result.IsOK = $false
        $Result.ErrorMessage = "Decoder has no Result property."
        Write-Output $Result
        return
    }
    
    <# 
    Check if all result properties in the Decoder are valid.
    Each PSCustomObject in a Decoder defines one property in the result object. It must include at least
    an array with the name 'Excerpt' and a string called 'Value'.
    Furthermore it could contain the strings 'Name' and 'Type' but all other keys are not allowed.
    #>
    foreach ($PropertyName in $ResultProperties)
    {
        # Properies 'Excerpt' and 'Value' are mandatory.    
        $Excerpt = $InputObject."$PropertyName".Excerpt
        if ((-not $Excerpt) -or ($Excerpt -isnot [array]))
        {
            $Result.IsOK = $false
            $Result.ErrorMessage = "Property ($PropertyName) has no Excerpt or it is not an array."
            Write-Output $Result
            return
        }

        $Value = $InputObject."$PropertyName".Value
        if ((-not $Value) -or ($Value -isnot [string]))
        {
            $Result.IsOK = $false
            $Result.ErrorMessage = "Property ($PropertyName) has no Value or ist is not a string."
            Write-Output $Result
            return
        }

        # Check the optional property 'Name'.
        $Name = $InputObject."$PropertyName".Name
        if ($Name -and ($Name -isnot [string]))
        {
            $Result.IsOK = $false
            $Result.ErrorMessage = "Name item of oroperty ($PropertyName) is not a string."
            Write-Output $Result
            return
        }

        # Check the optional property 'Type'.
        $Type = $InputObject."$PropertyName".Type
        if ($Type)
        {
            if ($Type -isnot [string])
            {
                $Result.IsOK = $false
                $Result.ErrorMessage = "Type item of property ($PropertyName) is not a string."
                Write-Output $Result
                return
            }

            # Check if we have a .NET Type.
            if (-not ($Type -as [type])) {
                $Result.IsOK = $false
                $Result.ErrorMessage = "Type item of property ($PropertyName) is not a valid .NET-Type."
                Write-Output $Result
                return
            }
            
            # Check if the 'Type' does have a Parse method.
            try
            { 
                $TestObject = New-Object -TypeName $Type -ErrorAction Stop
                $HasParseMethod = Get-Member -InputObject $TestObject -Static -Name Parse -ErrorAction Stop
                if (-Not $HasParseMethod)
                {
                    $Result.IsOK = $false
                    $Result.ErrorMessage = "Type item of property ($PropertyName) has not a usable type."    
                }
            }
            catch
            {
                $Result.IsOK = $false
                $Result.ErrorMessage = "Type item of property ($PropertyName) has not a usable type."
            }
        }
        
    }# End of check result properties.

    Write-Output $Result
 
}# End of function Test-CliDecoder

