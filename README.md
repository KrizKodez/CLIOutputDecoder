![PowerShell](https://img.shields.io/badge/powershell-5391FE?style=flat&logo=powershell&logoColor=white)&nbsp;&nbsp;&nbsp;[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-green)](https://www.gnu.org/licenses/gpl-3.0)

# CLIOutputDecoder
A declarativ way to excerpt text data from different text sources.

## Motivation
As an System-Administrator there are lot of situations where you have to get information out of an array of strings, sometimes you must use a Non-PowerShell CLI command like dcdiag, nslookup or klist.exe which does not output data as PowerShell objects or you are using a PowerShell Cmdlet but the data which you want is only stored as plain text like messages from the Windows EventLog. I found myself to write more or less the same code in different scripts and for different customers in different ways and always remembering that I have written the same snipet already but dont want to start searching. So then the idea was born to convert text data into PowerShell objects in a declarative way and store the so called 'Decoders' in a dedicated directory i.e. into a PowerShell module.

## Installation
The installation is only a simple copy of the PowerShell module and save it where Autoloading feature is searching like
```PowerShell
$HOME\Documents\WindowsPowerShell\Modules
```

## Description
If you want to catch the Domain Controller SRV Records with the nslookup command you get typically the following output:
```
C:> nslookup -type=srv _ldap._tcp.dc._msdcs.domain.local
Server:  dnsserver.domain.local
Address:  10.233.72.20

_ldap._tcp.dc._msdcs.domain.local    SRV service location:
        priority       = 0
        weight         = 100
        port           = 389
        svr hostname   = dcname1.domain.local
_ldap._tcp.dc._msdcs.domain.local    SRV service location:
        priority       = 0
        weight         = 100
        port           = 389
        svr hostname   = dcname2.domain.local
        .
        .
        . etc pp.
```
You can see in this example the data is organized in a kind of 'blocks' and it would be great if we could get data like the server name and the values for priority, weight and the port of each block in a separate PowerShell object.

## Usage Example
Now we have a Decoder called 'nslookupDCs' in our Repo which we could use in the following way:

```PowerShell
	C:> nslookup -type=srv _ldap._tcp.dc._msdcs.domain.local | ConvertFrom-CLIOutput -Decoder nslookupDCs

	Host                          Priority Port Weight
	----                          -------- ---- ------
	dcnam1.domain.local            0        389  100
	dcname2.domain.local           0        389  100
```
We pipe the ouput of the CLI command to the ConvertFrom-CliOutput function and specify the name of the Decoder which has to be used. The ouput is a collection of PSCustomObjects with the data we want to be catched from the stream.

## CREATING A DECODER FILE
A Decoder is a JSON file with some specific keys and values:
```JSON
	{
		"Description": "List DC SRV records of a domain.",
		"Source": "nslookup",
		"Parameter": "-type=srv _ldap._tcp.dc._msdcs.<DomainName>",
		"Skip": 0,
		"Header": null,
		"Footer": null,
		"Separator": [
						"^\\s*$",
						"^_ldap\\._tcp\\.dc\\._msdcs"   
		],
		"Host": {
			"Excerpt": ["svr hostname\\s+= (.*)"],
			"Value": "RegEx0.Group0"
		},
		"Priority": {
			"Excerpt": ["priority\\s+= (.*)"],
			"Value": "RegEx0.Group0"
		},
		"Port": {
			"Excerpt": ["port\\s+= (.*)"],
			"Value": "RegEx0.Group0"
		},
		"Weight": {
			"Excerpt": ["weight\\s+= (.*)"],
			"Value": "RegEx0.Group0"
		}
	}
```
**DESCRIPTION**

Describes the kind of data which will be catched by the decoder.

**SOURCE**

The name of the CLI command used to get the output or another source.

**PARAMETER**

The parameter string used in the CLI command to get the output.

**SKIP**

The number of lines in the output which should be skipped absolutely. The value must be an integer.

**HEADER**

A RegEx to detect the header line of the data stream. All lines before the header will be ignored.
The SKIP value has the higher priority means if the skip value cause to jump over the header line 
and the HEADER has been defined the rest of the data will be ignored because the header could not be found anymore.
The best is to use SKIP and HEADER mutual exclusive.

**FOOTER**

A RegEx to detect the footer line of the data stream. All lines behind the footer will be ignored and the next object
in the pipe will be parsed.

**SEPARATOR**

An array of RegEx to detect the start or stop of a block of lines. The Decoder uses all of its items in a locical OR so if at least one of the SEPARATOR patterns match a separator line has been detected and the next object will be created.

**PROPERTY**

The rest of the keys in the example are defining the properties which the result PSCustomObject should have. Each property is a JSON object with different keys:

* **KEY**

This is the name of the property in the PSCustomObject.

* **EXCERPT**

An array of RegEx to detect the data for the property. Each RegEx item in the array will be used one time in a block of lines
in the same order as defined in the array. A property is only complete if all RegEx items of the EXCERPT has been matched.
The RegEx must have capture groups to get the data from the stream.
You could use a localized EXCERPT if you add the UICulture name to the key name in the form EXCERPT_UICultureName e.g. EXCERPT_de-DE

* **VALUE**

A string which creates the value of the property out of the EXCERPT RegEx items. To identify the results from the EXCERPT items
we use the following syntax:
    RegEx0.Group0 is the result from the first capture group from the first RegEx pattern in the EXCERPT array.
You could create an arbitrary string which includes the RegEx.Group items e.g.
    "Value": "This is my Servername: RegEx0.Group0 from OU: RegEx1.Group2"
The function will try to replace each RegEx.Group string with the result from the capture group.

* **TYPE**

Optional string representing a .NET Type. The function will try to convert the VALUE into this type after it has trimmed.

**THE SECTION KEY**

A key called SECTION is a reserved key which does not behave exactly the same like arbitrary keys. While normal properties are evaluated
in a block of lines means between two SEPARATORs the SECTION key is used to identify sections means groups of blocks.



## Contributing
All PowerShell developers are very welcome to help and make the code better, more readable or contribute new ideas. But also new Decoders or new ideas for Decoders could be helpful if someone has some basic skills with Regular Expressions.


## License

This project is licensed under the terms of the GPL V3 license. Please see the included Licence.txt file gor more details.

## Release History
