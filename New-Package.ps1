<#
.SYNOPSIS
Sets the version number for the GitAutomation module.
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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Modules\Silk' -Resolve)

$manifestPath = Join-Path -Path $PSScriptRoot -ChildPath 'GitAutomation\GitAutomation.psd1'

$manifest = Test-ModuleManifest -Path $manifestPath
if( -not $manifest )
{
    return
}

$nuspecPath = Join-Path -Path $PSScriptRoot -ChildPath 'GitAutomation.nuspec' -Resolve
$releaseNotesPath = Join-Path -Path $PSScriptRoot -ChildPath 'RELEASE_NOTES.md' -Resolve

Set-ModuleVersion -ManifestPath $manifestPath `
                  -Version $Version `
                  -PreReleaseVersion $PreReleaseVersion `
                  -BuildMetadata $BuildMetadata `
                  -ReleaseNotesPath (Join-Path -Path $PSScriptRoot -ChildPath 'RELEASE_NOTES.md' -Resolve) `
                  -NuspecPath (Join-Path -Path $PSScriptRoot -ChildPath 'GitAutomation.nuspec' -Resolve) `
                  -SolutionPath (Join-Path -Path $PSScriptRoot -ChildPath 'Source\Git.Automation.sln' -Resolve) `
                  -AssemblyInfoPath (Join-Path -Path $PSScriptRoot -ChildPath 'Source\Git.Automation\Properties\AssemblyInfo.cs' -Resolve)

$valid = Assert-ModuleVersion -ManifestPath $manifestPath -ReleaseNotesPath $releaseNotesPath -NuspecPath $nuspecPath -ExcludeAssembly 'LibGit2Sharp.dll'
if( -not $valid )
{
    Write-Error -Message ('GitAutomation isn''t at the right version. Please use the -Version parameter to set the version.')
    return
}

Set-ReleaseNotesReleaseDate -ManifestPath $manifestPath -ReleaseNotesPath $releaseNotesPath

$tags = @( 'git', 'vcs', 'rcs', 'automation', 'github', 'gitlab', 'libgit2' )

Set-ModuleManifestMetadata -ManifestPath $manifestPath -Tag $tags -ReleaseNotesPath $releaseNotesPath

Set-ModuleNuspec -ManifestPath $manifestPath -NuspecPath $nuspecPath -ReleaseNotesPath $releaseNotesPath -Tags $tags

$outputDirectory = Join-Path -Path $PSScriptRoot -ChildPath '.output'
if( (Test-Path -Path $outputDirectory -PathType Container) )
{
    Get-ChildItem -Path $outputDirectory | Remove-Item -Recurse
}
else
{
    New-Item -Path $outputDirectory -ItemType 'directory'
}

$manifestPath = Join-Path -Path $PSScriptRoot -ChildPath 'GitAutomation\GitAutomation.psd1'
New-NuGetPackage -OutputDirectory (Join-Path -Path $outputDirectory -ChildPath 'nuget.org') `
                 -ManifestPath $manifestPath `
                 -NuspecPath $nuspecPath `
                 -NuspecBasePath $PSScriptRoot `
                 -PackageName 'GitAutomation'

New-ChocolateyPackage -OutputDirectory (Join-Path -Path $outputDirectory -ChildPath 'chocolatey.org') `
                      -ManifestPath $manifestPath `
                      -NuspecPath $nuspecPath

$source = Join-Path -Path $PSScriptRoot -ChildPath 'GitAutomation'
$destination = Join-Path -Path $outputDirectory -ChildPath 'GitAutomation'
robocopy.exe $source $destination /MIR /NJH /NJS /NP /NDL /XD /XF '*.pdb'
if( $LASTEXITCODE -lt 8 )
{
    $LASTEXITCODE = 0
}

Get-ChildItem -Path 'RELEASE_NOTES.md','LICENSE','NOTICE' | Copy-Item -Destination $destination

exit 0
