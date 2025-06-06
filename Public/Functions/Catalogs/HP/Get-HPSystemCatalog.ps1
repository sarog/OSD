<#
.SYNOPSIS
Converts the HP Client Catalog for Microsoft System Center Product to a PowerShell Object

.DESCRIPTION
Converts the HP Client Catalog for Microsoft System Center Product to a PowerShell Object
Requires Internet Access to download HpCatalogForSms.latest.cab

.EXAMPLE
Get-HPSystemCatalog
Don't do this, you will get an almost endless list

.EXAMPLE
$Results = Get-HPSystemCatalog
Yes do this.  Save it in a Variable

.EXAMPLE
Get-HPSystemCatalog -Component BIOS | Out-GridView
Displays all the HP BIOS updates in GridView

.LINK
https://github.com/OSDeploy/OSD/tree/master/Docs

.NOTES
#>
function Get-HPSystemCatalog {
    [CmdletBinding()]
    param (
        #Specifies a download path for matching results displayed in Out-GridView
        [System.String]
        $DownloadPath,

        #Limits the results to match the current system
        [System.Management.Automation.SwitchParameter]
        $Compatible,

        #Limits the results to a specified component
        [ValidateSet('Software','Firmware','Driver','Accessories Firmware and Driver','BIOS')]
        [System.String]
        $Component
    )
    #=================================================
    #   Import Catalog
    #=================================================
    $CatalogFile = "$(Get-OSDCachePath)\hp-catalogs\build-system.xml"
    Write-Verbose "Importing the Offline Catalog at $CatalogFile"
    $Results = Import-Clixml -Path $CatalogFile
    #=================================================
    #   Compatible
    #=================================================
    if ($PSBoundParameters.ContainsKey('Compatible')) {
        $MyComputerProduct = Get-MyComputerProduct
        Write-Verbose "Filtering Catalog for items compatible with Product $MyComputerProduct"
        $Results = $Results | Where-Object {$_.SupportedSystemID -contains $MyComputerProduct}
    }
    #=================================================
    #   Component
    #=================================================
    if ($PSBoundParameters.ContainsKey('Component')) {
        Write-Verbose "Filtering Catalog for $Component"
        switch ($Component) {
            'BIOS'{
                $Results = $Results | Where-Object {$_.Component -eq 'BIOS'}
            }
            'Firmware'{
                $Results = $Results | Where-Object{$_.Component -eq 'Firmware' -and $_.Description -notlike "*NOTE: THIS BIOS UPDATE*"}
            }
            default {
                $Results = $Results | Where-Object {$_.Component -eq $Component}
            }
        }
    }
    #=================================================
    #   DownloadPath
    #=================================================
    if ($PSBoundParameters.ContainsKey('DownloadPath')) {
        $Results = $Results | Out-GridView -Title 'Select one or more files to Download' -PassThru -ErrorAction Stop
        foreach ($Item in $Results) {
            $OutFile = Save-WebFile -SourceUrl $Item.Url -DestinationDirectory $DownloadPath -DestinationName $Item.FileName -Verbose
            $Item | ConvertTo-Json | Out-File "$($OutFile.FullName).json" -Encoding ascii -Width 2000 -Force
        }
    }
    #=================================================
    #   Complete
    #=================================================
    $Results
    #=================================================
}