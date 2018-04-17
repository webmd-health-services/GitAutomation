<#
.SYNOPSIS
Chocolately install script for GitAutomation.
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
# limitations under the License.[CmdletBinding()]

param(
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'
$ErrorActionPreference = 'Stop'

function Get-PowerShellModuleInstallPath
{
    <#
    .SYNOPSIS
    Returns the path to the directory where you can install custom modules.

    .DESCRIPTION
    Custom modules should be installed under the `Program Files` directory. This function looks at the `PSModulePath` environment variable to find the install location under `Program Files`. If that path isn't part of the `PSModulePath` environment variable, returns the module path under `$PSHOME`. If that isn't part of the `PSModulePath` environment variable, an error is written and nothing is returned.

    `Get-PowerShellModuleInstallPath` is new in Carbon 2.0.

    .EXAMPLE
    Get-PowerShellModuleInstallPath

    Demonstrates how to get the path where modules should be installed.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
    )

    Set-StrictMode -Version 'Latest'

    $modulePaths = $env:PSModulePath -split ';'

    $programFileModulePath = Join-Path -Path $env:ProgramFiles -ChildPath 'WindowsPowerShell\Modules'
    $installRoot = $modulePaths | 
                        Where-Object { $_.TrimEnd('\') -eq $programFileModulePath } |
                        Select-Object -First 1
    if( $installRoot )
    {
        return $programFileModulePath
    }

    $psHomeModulePath = Join-Path -Path $PSHOME -ChildPath 'Modules'

    $installRoot = $modulePaths | 
                        Where-Object { $_.TrimEnd('\') -eq $psHomeModulePath } |
                        Select-Object -First 1
    if( $installRoot )
    {
        return $psHomeModulePath
    }

    Write-Error -Message ('PSModulePaths ''{0}'' and ''{1}'' not found in the PSModulePath environment variable.' -f $programFileModulePath,$psHomeModulePath)
}

$installPath = Get-PowerShellModuleInstallPath
$installPath = Join-Path -Path $installPath -ChildPath 'GitAutomation'

$source = Join-Path -Path $PSScriptRoot -ChildPath '..\GitAutomation' -Resolve
if( -not $source )
{
    return
}

if( (Test-Path -Path $installPath -PathType Container) )
{
    $newName = 'GitAutomation{0}' -f [IO.Path]::GetRandomFileName()
    Write-Verbose ('Renaming existing GitAutomation module: {0} -> {1}' -f $installPath,$newName)
    Rename-Item -Path $installPath $newName
    $oldModulePath = Join-Path -Path (Get-PowerShellModuleInstallPath) -ChildPath $newName
    if( Test-Path -Path $oldModulePath -PathType Container )
    {
        Write-Verbose ('Removing old GitAutomation module: {0}' -f $oldModulePath)
        Remove-Item -Path $oldModulePath -Force -Recurse
    }
    else
    {
        return
    }

    if( Test-Path -Path $oldModulePath -PathType Container )
    {
        return
    }
}

Write-Verbose -Message ('Installing GitAutomation: {0} -> {1}' -f $source,$installPath)
Copy-Item -Path $source -Destination $installPath -Recurse
