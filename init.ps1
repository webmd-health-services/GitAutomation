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

Set-StrictMode -Version 'Latest'

$PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition

$carbonVersion = '2.2.0'
$pesterVersion = '3.4.3'
$packagesRoot = Join-Path -Path $PSScriptRoot -ChildPath 'packages'

$nugetExePath = Join-Path -Path $PSScriptRoot -ChildPath '.\Tools\NuGet\nuget.exe' -Resolve

& $nugetExePath install 'Carbon' -Version $carbonVersion -OutputDirectory $packagesRoot
& $nugetExePath install 'Pester' -Version $pesterVersion -OutputDirectory $packagesRoot

$carbonRoot = Join-Path -Path $packagesRoot -ChildPath ('Carbon.{0}\Carbon' -f $carbonVersion)

if( -not (Get-Module -Name 'Carbon') )
{
    & (Join-Path -Path $carbonRoot -ChildPath 'Import-Carbon.ps1' -Resolve)
}

Install-Junction -Link (Join-Path -Path $packagesRoot -ChildPath 'Pester') -Target (Join-Path -Path $packagesRoot -ChildPath ('Pester.{0}\tools' -f $pesterVersion))
Install-Junction -Link (Join-Path -Path $packagesRoot -ChildPath 'Carbon') -Target $carbonRoot

if( -not (Get-Module -Name 'LibGit2') )
{
    & (Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2\Import-LibGit2.ps1' -Resolve)
}

$silkRoot = Join-Path -Path $packagesRoot -ChildPath 'Silk'
if( -not (Test-Path -Path $silkRoot -PathType Container) )
{
    Copy-GitRepository -Source 'https://github.com/splatteredbits/Silk' -DestinationPath $silkRoot
}

git -C $silkRoot fetch
git -C $silkRoot checkout master -q

$websiteRoot = Join-Path -Path $PSScriptRoot -ChildPath 'get-libgit2.org'
if( -not (Test-Path -Path $websiteRoot -PathType Container) )
{
    Copy-GitRepository -Source 'https://github.com/splatteredbits/get-libgit2.org' -DestinationPath $websiteRoot
}

git -C $websiteRoot fetch
git -C $websiteRoot checkout master -q

& (Join-Path -Path $PSScriptRoot -ChildPath 'build.ps1')
