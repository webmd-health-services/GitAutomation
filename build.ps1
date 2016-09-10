<#
.SYNOPSIS
Sets the version number for the LibGit2 module.
#>
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
[CmdletBinding()]
param(
    [Version]
    # The version to build. If not supplied, build the version as currently defined.
    $Version,

    [string]
    # The pre-release version, e.g. alpha.39, rc.1, etc.
    $PreReleaseVersion,

    [string]
    # Build metadata.
    $BuildMetadata
)

#Requires -Version 4
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

& (Join-Path -Path $PSScriptRoot -ChildPath 'packages\Silk\Silk\Import-Silk.ps1' -Resolve)

Set-ModuleVersion -ManifestPath (Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2\LibGit2.psd1') `
                  -Version $Version `
                  -PreReleaseVersion $PreReleaseVersion `
                  -BuildMetadata $BuildMetadata `
                  -ReleaseNotesPath (Join-Path -Path $PSScriptRoot -ChildPath 'RELEASE_NOTES.md' -Resolve) `
                  -NuspecPath (Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2.PowerShell.nuspec' -Resolve) `
                  -SolutionPath (Join-Path -Path $PSScriptRoot -ChildPath 'Source\LibGit2.Automation.sln' -Resolve) `
                  -AssemblyInfoPath (Join-Path -Path $PSScriptRoot -ChildPath 'Source\LibGit2.Automation\Properties\AssemblyInfo.cs' -Resolve)

$source = Join-Path -Path $PSScriptRoot -ChildPath 'Source\LibGit2.Automation\bin\Debug'
$destination = Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2\bin'
robocopy.exe $source $destination /MIR /NJH /NJS /NP /NDL /XD

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'packages\Pester' -Resolve)

$result = Invoke-Pester -Script (Join-Path -Path $PSScriptRoot -ChildPath 'Tests') -PassThru
if( $result.FailedCount )
{
    exit
}

$outputDirectory = Join-Path -Path $PSScriptRoot -ChildPath 'Output'
if( (Test-Path -Path $outputDirectory -PathType Container) )
{
    Get-ChildItem -Path $outputDirectory | Remove-Item -Recurse
}
else
{
    New-Item -Path $outputDirectory -ItemType 'directory'
}

$manifestPath = Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2\LibGit2.psd1'
New-NuGetPackage -OutputDirectory (Join-Path -Path $outputDirectory -ChildPath 'nuget.org') `
                 -ManifestPath $manifestPath `
                 -NuspecPath (Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2.PowerShell.nuspec') `
                 -NuspecBasePath $PSScriptRoot `
                 -PackageName 'LibGit2.PowerShell'

New-ChocolateyPackage -OutputDirectory (Join-Path -Path $outputDirectory -ChildPath 'chocolatey.org') `
                      -ManifestPath $manifestPath `
                      -NuspecPath (Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2.PowerShell.nuspec')

$source = Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2'
$destination = Join-Path -Path $outputDirectory -ChildPath 'LibGit2'
robocopy.exe $source $destination /MIR /NJH /NJS /NP /NDL /XD /XF '*.pdb'

Get-ChildItem -Path 'RELEASE_NOTES.md','LICENSE','NOTICE' | Copy-Item -Destination $destination