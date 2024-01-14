<#PSScriptInfo

.VERSION 1.0.0

.GUID 98CF7F40-F32D-4222-85AC-082C7AF40E60

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
    2023-01-06, 0.1.1, Christoph Rust, Corrected bug in Header detection.
    2023-02-26, 0.1.2, Christoph Rust, Corrected the action if the Footer has been detected.
    2023-02-26, 0.1.2, Christoph Rust, Use of the Parse method if Decoder property has a 'Type' defined.
    2024-01-14, 0.2.0, Christoph Rust, A Decoder property support now a localized 'Excerpt' key.

#>

<#
.Synopsis
    Convert output text from CLI commands to PSCustomObjects.        

.Description
    This functions filters data from text files with regular expresssions
    in the case that the text data is block orientated means each block is separated
    through a special line which could be detected by a RegEx. The data from each block
    will then be converted into a PSCustomObject. You could define Decoders
    to cover output data from different sources or commands.  

.Inputs
    System.String
    System.IO.FileInfo
    System.Management.Automation.PSCustomObject
    
    FileInfo object of the text file which to be parsed.
    Name or object of a Decoder to be used.
    
    You can pipe input to this cmdlet.

.Outputs
    PSCustomObject
    
    Each object is representing data of one block of lines.
 
.Notes
    The function has the alias 'to'.    

.Link
 
.Example
    Get-Item .\DoubleSPN.txt | ConvertFrom-CliOutput -Decoder QueryDuplicateSPN

    Takes the file object of the output of the SetSPN tool which has been used to query doubled SPNs.

.Example
    nslookup -type=srv _ldap._tcp.dc._msdcs.<DomainName> | ConvertFrom-CliOutput -Decoder nslookupDCs

    Takes the output from nslookup and returns a list of DC DNS records.

.Example
    gpresult /scope computer /v | to -Decoder ComputerPolicy

    The data from the gpresult query will be converted with the decoder ComputerPolicy
    In this example we use the 'to' alias.

.Example
    You could define a short decoder in a script without storing it in the 'Decoder' subdirectory.

    $ScriptDecoder = @{Skip=0 ; Separator=@() ; Host=@{ Excerpt=["svr hostname\\s+= (.*)"];Value="RegEx0.Group0" } }
    $CliOutput = nslookup -type=srv _ldap._tcp.dc._msdcs.domain.local
    $Result = ConvertFrom-CliOutput -InputData $CliOutput -DecoderObject $ScriptDecoder

    The variable $ScriptDecoder must ba a hashtable with at least the keys 'Skip','Separator' and a result property here 'Host'.
    'Host' must be a hashtable with at least the keys 'Exceprt' and 'Value'.

.Parameter FileInfo
    FileInfo object of the text file which has to be parsed.
    Use the Get-Item Cmdlet to get one or multiple FileInfo object(s) returned.

.Parameter Data
    Array of text lines to be processed.

.Parameter Decoder
    Name of the Decoder to be used.

.Parameter DecoderObject
    A PSCustomObject Decoder.
    Use this parameter to define a Decoder in a script.

#>
function ConvertFrom-CliOutput
{
    [CmdletBinding()]
    param
    (
        [Parameter(ParameterSetName='File',
        Mandatory=$true,
        ValueFromPipeline=$true,
        Position = 0)]
        [System.IO.FileInfo]$FileInfo,
                                 
        [Parameter(ParameterSetName='Array',
        Mandatory=$true,
        ValueFromPipeline=$true,
        Position=0)]
        [AllowEmptyString()]
        [string[]]$InputData,
        
        [Parameter(Position=1)]
        [string]$Decoder,

        [pscustomobject]$DecoderObject

    )
    
    begin
    {
        # Try to load the Decoder from the Decoder directory and save it into the 'SelectedDecoder' variable.
        if ($Decoder) {
            try { $FoundDecoder = Get-CliDecoder -Name $Decoder -ErrorAction Stop }
            catch {
                Write-Error -Message "Could not load Decoder." -TargetObject $Decoder -Category InvalidArgument
                break
            }
            
            # We must break if no decoder or more than one has been found.
            if (-not $FoundDecoder) {
                Write-Error -Message "No Decoder has been found." -TargetObject $Decoder -Category ObjectNotFound
                break
            }
            if ($FoundDecoder.Count -gt 1) {
                Write-Error -Message "Decoder is not unambiguous." -TargetObject $Decoder -Category InvalidArgument
                break
            }
            $SelectedDecoder = $FoundDecoder
        }
        elseif ($DecoderObject) {
            if ($DecoderObject -isnot [pscustomobject]) {
                Write-Error -Message "Parameter (DecoderObject) has not the correct type." -TargetObject $DecoderObject -Category InvalidArgument
                break
            }

            # Convert existing hashtables into PSCustomObject type to allow the testing of the 'DecoderObject'.
            foreach ($Property in $DecoderObject.psobject.Properties) {
                if ($Property.TypeNameOfValue -ne 'System.Collections.Hashtable') { Continue }
                $DecoderObject."$($Property.Name)" = [pscustomobject]($DecoderObject."$($Property.Name)")
            }

            # Because the decoder is not loaded from the Decoder directory we must do a separate test.
            $Test = Test-CliDecoder -InputObject $DecoderObject -Script
            if (-not $Test.IsOK) {
                Write-Error -Message ($Test.ErrorMessage) -Category InvalidArgument
                break
            }
            $SelectedDecoder = $DecoderObject
        }
        else {
            Write-Error -Message "No decoder has been defined." -Category InvalidArgument
            break
        }

        # Find all result properties in the defined Decoder. Result properties must be of type PSCustomObject.
        $ResultProperties = @()
        foreach ($Property in $SelectedDecoder.psobject.Properties) {
            if ($Property.TypeNameOfValue -ne 'System.Management.Automation.PSCustomObject') { Continue }
            $ResultProperties += $Property.Name

            # Check if we have a localized 'Excerpt' key in the property.
            $UICultureName = ([cultureinfo]::CurrentUICulture).Name
            if ($SelectedDecoder."$($Property.Name)"."Excerpt_$UICUltureName") {
                $SelectedDecoder."$($Property.Name)".Excerpt = $SelectedDecoder."$($Property.Name)"."Excerpt_$UICUltureName"
            }
        }

        # Add additional control data to each result property defined in the Decoder.
        foreach ($ResultProperty in $ResultProperties)
        {
            # This members are only used at runtime of the Decoder.
            $SelectedDecoder."$ResultProperty" | Add-Member -NotePropertyName ExcerptIndex -NotePropertyValue 0
            $SelectedDecoder."$ResultProperty" | Add-Member -NotePropertyName Values -NotePropertyValue @()
            $SelectedDecoder."$ResultProperty" | Add-Member -NotePropertyName IsNameDefined -NotePropertyValue $true
            $SelectedDecoder."$ResultProperty" | Add-Member -NotePropertyName Completed -NotePropertyValue $false
            $SelectedDecoder."$ResultProperty" | Add-Member -NotePropertyName RegExData -NotePropertyValue @{}
            
            # If the 'Name' property is not defined in the result property we create it with the name of the result property itself.
            if (-not $SelectedDecoder."$ResultProperty".Name) { 
                $SelectedDecoder."$ResultProperty" | Add-Member -NotePropertyName Name -NotePropertyValue ($ResultProperty.Trim(" "))
            }

            # if the 'Name' property contains a capture group name e.g. 'RegEx0.Group0' we must flag that in the result property.
            if ($SelectedDecoder."$ResultProperty".Name -match 'RegEx[0-9]{1,2}\.Group[0-9]{1,2}') {
                $SelectedDecoder."$ResultProperty".IsNameDefined = $false    
            }
        }

        # Reset the flag to identify the header line.
        $HasHeaderNotFound = $true

    }# End of begin block 

    process   
    {    
        # If we pipe a FileInfo object we must read the data first.
        if ($PSCmdlet.ParameterSetName -eq 'File') {
            $Data = [System.IO.File]::ReadAllLines($FileInfo.FullName)
            
            # Reset the flag to identify the header line for each new file.
            $HasHeaderNotFound = $true
        }
        else { $Data = $InputData }

        # Parse through all data lines.
        foreach ($Line in $Data)
        {
            # Skip the first lines.
            if ($SelectedDecoder.Skip -gt 0) {
                $SelectedDecoder.Skip--
                continue
            }

            # Skip until the Header has been found.
            if ($SelectedDecoder.Header -and $HasHeaderNotFound) {
                if ($Line -match $SelectedDecoder.Header) { $HasHeaderNotFound = $false }
                continue
            }

            # Skip the rest of the data lines if the footer has been found.
            if ($SelectedDecoder.Footer -and ($Line -match $SelectedDecoder.Footer)) { 
                if ($PSCmdlet.ParameterSetName -eq 'File') { return } # Take the next file.
                else                                       { break }  # End the complete process block.
            }
            
            # Check all result properties for this line of content.
            foreach ($ResultProperty in $ResultProperties)
            {
                # This is only to shorten code lines.
                $Property = $SelectedDecoder."$ResultProperty"
                
                # Skip the property if the actual Excerpt RegEx does not match.
                if ($Line -notmatch $Property.Excerpt[$Property.ExcerptIndex]) { continue }

                # If we have the 'Section' property we must check if it has to be reset.
                if (($ResultProperty -eq 'Section') -and $Property.Completed) {
                    $Property.Completed = $false
                    $Property.Values = @()
                }
                
                # Catch all capture group data.
                for ($i = 1 ;$i -le $matches.Count-1;$i++) {
                    $Keyname = "RegEx" + $Property.ExcerptIndex + ".Group" + ($i-1)
                    $Property.RegExData.Add($Keyname,$matches[$i])
                }
                
                # Increment the index that we use the next Excerpt RegEx in the next line.
                $Property.ExcerptIndex++
                
                # Skip to the next result property if not all 'Excerpt' RegEx have been matched.
                if ($Property.ExcerptIndex -ne $Property.Excerpt.Count) { continue }
                
                # Built the result property 'Name' out of the RegEx capture group data...
                if (-not $Property.IsNameDefined) {
                    foreach ($Key in $Property.RegExData.Keys) {
                        $Property.Name = ($Property.Name -replace $Key,$Property.RegExData[$Key]).Trim(" ")
                    }    
                }
                # ... anf if we still have capture group names in the 'Name' property after the first block of lines
                # we are using the static name of the result property instead and never change it again.
                if ($Property.Name -match 'RegEx[0-9]{1,2}\.Group[0-9]{1,2}') {
                    $Property.Name = $ResultProperty
                    $Property.IsNameDefined = $true
                }
                
                # Built the result property 'Value' out of the RegEx capture group data and keept in the array.
                # We trim the value always.
                $TempValue = $Property.Value
                foreach ($Key in $Property.RegExData.Keys) {
                    $TempValue = $TempValue -replace $Key,$Property.RegExData[$Key]
                }
                $TempValue = $TempValue.Trim(" ")
               
                # If we have a 'Type' defined for the value in the result property we try to convert it.
                if ($Property.Type) {
                    try { 
                        $TestCommand = "[$($Property.Type)]::Parse(" + "'" + $TempValue + "')"
                        $TempValue = Invoke-Expression -Command $TestCommand -ErrorAction Stop
                    } 
                    catch { $TempValue = $null }    
                }
                $Property.Values += $TempValue

                # Flag that all Excerpt RegEx have been matched (we have at least one result property) and reset the control data.
                # If we did not have reached the end of the block of lines the result property could catch the next name and its value.
                $Property.Completed = $true
                $Property.ExcerptIndex = 0
                $Property.RegExData = @{}

            }# End of check all properties for the actual data line.

            # Check if we have reached the end of a block defined through any of the Separator RegEx
            # and if not process the next data line.
            $HasAnySeparatorMatched = $false
            foreach ($Separator in $SelectedDecoder.Separator) {
                if ($Line -match $Separator) { $HasAnySeparatorMatched = $true }
            }
            if (-not $HasAnySeparatorMatched) { continue }

            # Create result PSCustomObject which will be returned.
            $Result = New-Object -TypeName PSCustomObject   
            $HasResultObjectData = $false

            foreach ($ResultProperty in $ResultProperties)
            {
                # This is only to shorten code lines.
                $Property = $SelectedDecoder."$ResultProperty"
                
                if ($Property.IsNameDefined) { $ResultName = $Property.Name }
                else                         { $ResultName = $ResultProperty }

                # Distinguish if the result 'Value' should be null, scalar or array.
                if (-not $Property.Completed) { $ResultValue = $null }
                else {
                    switch ($Property.Values.Count) 
                    {
                        0       { $ResultValue = $null }
                        1       { $ResultValue = $Property.Values[0] }
                        default { $ResultValue = $Property.Values }
                    }    
                }
            
                # Add the property to the Result object.
                $Result | Add-Member -NotePropertyName $ResultName -NotePropertyValue $ResultValue
                               
                # Reset control data of the property except if it is the 'Section' property.
                # and define if the result object has data to be returned.
                if ($ResultProperty -ne 'Section') {
                    $Property.Completed = $false
                    $Property.Values = @()
                    if ($ResultValue) { $HasResultObjectData = $true }
                }
    
            }# End of foreach all result properties in the SelectedDecoder.
            
            # If the result object has at least one property not null then return it.
            if ($HasResultObjectData) { Write-Output $Result }

        }# End of foreach all Data.

    }# End of process block

    end{}

}# End of function ConvertFrom-CliOutput


