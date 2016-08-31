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
$libGit2SharpVersion = '0.22.0'
$libGit2SharpNativeVersion = '1.0.129'
$pesterVersion = '3.4.3'
$packagesRoot = Join-Path -Path $PSScriptRoot -ChildPath 'packages'

$nugetExePath = Join-Path -Path $PSScriptRoot -ChildPath '.\Tools\NuGet\nuget.exe' -Resolve
& $nugetExePath install 'LibGit2Sharp.NativeBinaries' -Version $libGit2SharpNativeVersion -OutputDirectory $packagesRoot
& $nugetExePath install 'LibGit2Sharp' -Version $libGit2SharpVersion -OutputDirectory $packagesRoot
& $nugetExePath install 'Carbon' -Version $carbonVersion -OutputDirectory $packagesRoot
& $nugetExePath install 'Pester' -Version $pesterVersion -OutputDirectory $packagesRoot

& (Join-Path -Path $PSScriptRoot -ChildPath ('packages\Carbon.{0}\Carbon\Import-Carbon.ps1' -f $carbonVersion) -Resolve)

$binRoot = Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2\bin'
Install-Directory -Path $binRoot

$nativeBinaryRoot = Join-Path -Path $binRoot -ChildPath 'NativeBinaries'
Install-Directory -Path $nativeBinaryRoot

$source = Join-Path -Path $packagesRoot -ChildPath ('LibGit2Sharp.{0}\lib\net40' -f $libGit2SharpVersion)
$destination = $binRoot
robocopy.exe $source $destination /MIR /NJH /NJS /NP /NDL /XD $nativeBinaryRoot


$nativeBinaryLibRoot = Join-Path -Path $packagesRoot -ChildPath ('LibGit2Sharp.NativeBinaries.{0}\libgit2' -f $libGit2SharpNativeVersion)
@( 
    'linux',
    'osx',
    'windows\amd64',
    'windows\x86'
) | ForEach-Object {
    $source = Join-Path -Path $nativeBinaryLibRoot -ChildPath $_
    $destination = Join-Path -Path $nativeBinaryRoot -ChildPath (Split-Path -Leaf -Path $_)
    robocopy.exe $source $destination /MIR /NJH /NJS /NP /NDL
}

Install-Junction -Link (Join-Path -Path $packagesRoot -ChildPath 'Pester') -Target (Join-Path -Path $packagesRoot -ChildPath ('Pester.{0}\tools' -f $pesterVersion))

& (Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2\Import-LibGit2.ps1' -Resolve)

$silkRoot = Join-Path -Path $packagesRoot -ChildPath 'Silk'
if( -not (Test-Path -Path $silkRoot -PathType Container) )
{
    Copy-GitRepository -Source 'https://github.com/splatteredbits/Silk' -DestinationPath $silkRoot
}

git -C $silkRoot fetch
git -C $silkRoot checkout master -q
