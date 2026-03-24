[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [String] $Source,

    [String] $DestinationPath
)

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'GitAutomation' -Resolve) -Force

Copy-GitRepository -Source $Source -DestinationPath $DestinationPath

Push-Location -Path $DestinationPath
try
{
    $branchName = "test/$(Get-Date -Format 'yyyyMMddHHmmss')"
    New-GitBranch -Name $branchName

    $items = @(
        'GitAutomation',
        'PSModules',
        'Source',
        'Tests'
    )

    foreach ($item in $items)
    {
        $sourcePath = Join-Path -Path $PSScriptRoot -ChildPath $item
        Copy-Item -Path $sourcePath -Destination '.' -Recurse
        Add-GitItem -Path $item
    }

    Save-GitCommit -Message 'Adding many files.'
    Send-GitCommit -SetUpstream
}
finally
{
    Pop-Location
}