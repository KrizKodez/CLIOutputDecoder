<#PSScriptInfo

.VERSION 0.1.0

.GUID 6C78AA73-711C-40FD-97D8-84F2FBC3839B

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

#>

<#
.Synopsis
    Get CLI Output Decoder.         

.Description
    List all or specific CLI Output Decoders which are included in the module.
    
.Inputs
    System.String
    Name of the Decoder.
        
    You cannot pipe input to this cmdlet.

.Outputs
    PSCustomObject
    
    Each object represents a Decoder definition.
 
.Notes
    The function has the alias 'decoder'.
 
.Link
 
.Example
    Get-CliDecoder 

    Show all defined Decoders of the module.

.Example
    Get-CliDecoder Get*

    Show all Decoders with names matching the filter 'Get*'.

        Decoder              Source         Parameter                                          Description
        -------              -------         ---------                                          -----------
        GetPackageInfo       dism            /online /Get-PackageInfo /PackageName:<PackageN... Get Package Information.
        GetPackages          dism            /online /Get-Packages                              List all installed packages.

.Parameter Name
    Name of a built-in CLI Output Decoder.
    You could use wildcards.

#>
function Get-CliDecoder
{
    [CmdletBinding()]
    param
    (
        [Parameter(Position=0)]
        [string]$Name='*'
    )

    # Get all decoder file objects from the 'Decoder' folder of the module.
    $SelectedDecoderFiles = @()
    if ($Name.Contains('*') -or $Name.Contains('?'))
    {
        # Here we get all Decoder files defined through the filter in the 'Name' parameter...
        $SelectedDecoderFiles = Get-ChildItem -Path $CliOutputBuiltinDecoders -Filter "$Name$CliOutputDecoderSuffix" -File
    }
    else
    {
        # ... and here all Decoder files which starts with the string defined in the 'Name' parameter.
        $ExistingDecoderFiles = Get-ChildItem -Path $CliOutputBuiltinDecoders -Filter "*$CliOutputDecoderSuffix" -File
        foreach ($DecoderFile in $ExistingDecoderFiles) {
            if ($DecoderFile.BaseName -match "^$Name") { $SelectedDecoderFiles += $DecoderFile }
        }
    }

    # Convert from JSON and test all selected decoder files.
    foreach ($DecoderFile in $SelectedDecoderFiles)
    {
        # Read the raw string data from the file and try to convert it from JSON type.
        $FileContent = Get-Content -Path $DecoderFile.FullName -Raw
        try   { $Result = ConvertFrom-Json -InputObject $FileContent -ErrorAction Stop }
        catch { 
            Write-Error -Message "Cannot convert JSON File." -TargetObject $DecoderFile.Name -Category InvalidResult 
            continue
        }

        # Check the decoder.
        $Test = Test-CliDecoder -InputObject $Result
        if (-not $Test.IsOK) {
            Write-Error -Message $Test.ErrorMessage -TargetObject $DecoderFile.Name -Category InvalidData
            continue
        }
                
        # Add the filename of the decoder as 'Decoder' property and an additional type name.
        $Result | Add-Member -NotePropertyName Decoder -NotePropertyValue $DecoderFile.BaseName
        $Result.PSTypeNames.Insert(0,'CliOutputDecoder')

        $Result

    }# End of foreach all existing decoder files.
 
}# End of function Get-CliDecoder

