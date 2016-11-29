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
    [Switch]
    $Clean
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

Install-PackageProvider -Name NuGet -Force -Scope CurrentUser

$moduleNames = @( 'Pester', 'Silk', 'Carbon' )
foreach( $moduleName in $moduleNames )
{
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath $moduleName
    if( (Test-Path -Path $modulePath -PathType Container) )
    {
        if( $Clean )
        {
            Remove-Item -Path $modulePath -Recurse -Force
        }

        continue
    }

    Save-Module -Name $moduleName -Path $PSScriptRoot -Force

    $versionDir = Join-Path -Path $modulePath -ChildPath '*.*.*'
    if( (Test-Path -Path $versionDir -PathType Container) )
    {
        $versionDir = Get-Item -Path $versionDir
        Get-ChildItem -Path $versionDir -Force | Move-Item -Destination $modulePath -Verbose
        Remove-Item -Path $versionDir
    }
}

$nugetPath = Join-Path -Path $PSScriptRoot -ChildPath '.\Silk\bin\NuGet.exe' -Resolve

$sourceRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Source'

Get-ChildItem -Path $sourceRoot -Filter 'packages.config' -Recurse |
    ForEach-Object { & $nugetPath restore $_.FullName -SolutionDirectory $sourceRoot }