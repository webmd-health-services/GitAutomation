<#
.SYNOPSIS
Packages and publishes LibGit2 packages.

.DESCRIPTION
The `Publish-LibGit2.ps1` script packages and publishes a version of the LibGit2 module. It uses the version defined in the LibGit2.psd1 file. Before publishing, it adds the current date to the version in the release notes, updates the module's website, then tags the latest revision with the version number. It then publishes the module to NuGet, Chocolatey, and the PowerShell Gallery. If the version of LibGit2 being published already exists in a location, it is not re-published. If the PowerShellGet module isn't installed, the module is not publishes to the PowerShell Gallery.

.EXAMPLE
Publish-LibGit2.ps1

Yup. That's it.
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

[CmdletBinding(SupportsShouldProcess=$true)]
param(
)

#Requires -Version 4
Set-StrictMode -Version Latest

& (Join-Path -Path $PSScriptRoot -ChildPath 'packages\Silk\Silk\Import-Silk.ps1' -Resolve)
& (Join-Path -Path $PSScriptRoot -ChildPath 'packages\Carbon\Import-Carbon.ps1' -Resolve)

$licenseFileName = 'LICENSE'
$noticeFileName = 'NOTICE'
$releaseNotesFileName = 'RELEASE_NOTES.md'
$releaseNotesPath = Join-Path -Path $PSScriptRoot -ChildPath $releaseNotesFileName -Resolve

$manifestPath = Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2\LibGit2.psd1'
$manifest = Test-ModuleManifest -Path $manifestPath
if( -not $manifest )
{
    return
}

$nuspecPath = Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2.PowerShell.nuspec'
$valid = Assert-ModuleVersion -ManifestPath $manifestPath -ReleaseNotesPath $releaseNotesPath -NuspecPath $nuspecPath -ExcludeAssembly 'LibGit2Sharp.dll'
if( -not $valid )
{
    Write-Error -Message ('LibGit2 isn''t at the right version. Please rebuild with build.ps1.')
    return
}

Set-ReleaseNotesReleaseDate -ManifestPath $manifestPath -ReleaseNotesPath $releaseNotesPath
if( (git status --porcelain $releaseNotesPath) )
{
    git add $releaseNotesPath
    git commit -m ('[{0}] Updating release date in release notes.' -f $manifest.Version) $releaseNotesPath
    git log -1
}

$tags = @( 'git', 'vcs', 'rcs', 'automation', 'github', 'gitlab', 'libgit2' )

Set-ModuleManifestMetadata -ManifestPath $manifestPath -Tag $tags -ReleaseNotesPath $releaseNotesPath
if( (git status --porcelain $manifestPath) )
{
    git add $manifestPath
    git commit -m ('[{0}] Updating module manifest.' -f $manifest.Version) $manifestPath
    git log -1
}

$nuspecPath = Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2.PowerShell.nuspec' -Resolve
if( -not $nuspecPath )
{
    return
}

Set-ModuleNuspec -ManifestPath $manifestPath -NuspecPath $nuspecPath -ReleaseNotesPath $releaseNotesPath -Tags $tags

if( (git status --porcelain $nuspecPath) )
{
    git add $nuspecPath
    git commit -m ('[{0}] Updating Nuspec settings.' -f $manifest.Version) $nuspecPath
    git log -1
}

if( -not (git tag | Where-Object { $_ -match ('^{0}$' -f [regex]::Escape($manifest.Version.ToString())) }) )
{
    git tag $manifest.Version.ToString()
}

# Create a clean clone so that our packages don't pick up any cruft.

& (Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2\Import-LibGit2.ps1' -Resolve)
$cloneDir = 'LibGit2+{0}' -f [IO.Path]::GetRandomFileName()
$cloneDir = Join-Path -Path $env:TEMP -ChildPath $cloneDir
Copy-GitRepository -Source '.' -DestinationPath $cloneDir

Push-Location -Path $cloneDir
try
{
    git checkout $manifest.Version
    .\init.ps1

    Publish-NuGetPackage -ManifestPath $manifestPath `
                         -NuspecPath (Join-Path -Path $cloneDir -ChildPath 'LibGit2.PowerShell.nuspec') `
                         -NuspecBasePath $cloneDir `
                         -Repository @( 'nuget.org', 'chocolatey.org' ) `
                         -PackageName 'LibGit2.PowerShell'

    Publish-PowerShellGalleryModule -ManifestPath $manifestPath `
                                    -ModulePath (Join-Path -Path $cloneDir -ChildPath 'LibGit2') `
                                    -ReleaseNotesPath $releaseNotesPath `
                                    -LicenseUri 'http://www.apache.org/licenses/LICENSE-2.0' `
                                    -ProjectUri 'https://github.com/splatteredbits/LibGit2.PowerShell/wiki' `
                                    -Tags $tags
}
finally
{
    Pop-Location
    Remove-Item -Path $cloneDir -Recurse -Force
}

