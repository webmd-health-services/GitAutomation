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

#Requires -Version 4
#Requires -RunAsAdministrator
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

$globalSearchPaths = [LibGit2Sharp.GlobalSettings]::GetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global)

function Get-TestRepoPath
{
    Join-Path -Path $TestDrive.FullName -ChildPath 'repo'
}

function GivenConfiguration
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        $Name,
        [Parameter(Mandatory,ParameterSetName='AtScope')]
        $AtScope,
        [Parameter(Mandatory,ParameterSetName='InFile')]
        $InFile
    )

    if( $AtScope )
    {
        Push-Location -Path (Get-TestRepoPath)
        try
        {
            Set-GitConfiguration -Name $Name -Value ([Guid]::NewGuid()) -Scope $AtScope
        }
        finally
        {
            Pop-Location
        }
    }

    if( $InFile )
    {
        Set-GitConfiguration -Name $Name -Value ([Guid]::NewGuid()) -Path (Join-Path -Path $TestDrive.FullName -ChildPath $InFile)
    }
}

function Init
{
    New-GitRepository -Path (Get-TestRepoPath)

    foreach( $setting in (Get-GitConfiguration | Where-Object { $_.Key -like 'gitautomation.*' }) )
    {
        Remove-GitConfiguration -Name $setting.Key -Scope $setting.Level
    }
}

function ThenConfiguration
{
    param(
        $Name,

        [Switch]
        $Not,

        [Parameter(Mandatory)]
        [Switch]
        $Exists,

        $InFile
    )

    $optionalParams = @{ }
    if( $InFile )
    {
        $optionalParams['Path'] = Join-Path -Path $TestDrive.FullName -ChildPath $InFile
    }

    Push-Location -Path (Get-TestRepoPath)
    try
    {
        if( $Not )
        {
            It ('should remove configuration') {
                Get-GitConfiguration -Name $name @optionalParams | Should -BeNullOrEmpty
            }
        }
        else
        {
            It ('should not remove configuration') {
                Get-GitConfiguration -Name $name @optionalParams | Should -Not -BeNullOrEmpty
            }
        }
    }
    finally
    {
        Pop-Location
    }
}

function ThenError
{
    param(
        [Parameter(Mandatory,ParameterSetName='IsEmpty')]
        [Switch]
        $IsEmpty,

        [Parameter(Mandatory,ParameterSetName='Matches')]
        $Matches
    )

    if( $IsEmpty )
    {
        It ('should not write an error') {
            $Global:Error | Should -BeNullOrEmpty
        }
    }

    if( $Matches )
    {
        It ('should write an error') {
            $Global:Error | Should -Match $Matches
        }
    }
}

function WhenRemoving
{
    [CmdletBinding()]
    param(
        $Name,
        $AtScope,
        $InWorkingDirectory,
        $InFile
    )

    $Global:Error.Clear()

    if( -not $InWorkingDirectory )
    {
        $InWorkingDirectory = Get-TestRepoPath
    }

    $optionalParams = @{ }
    if( $AtScope )
    {
        $optionalParams['Scope'] = $AtScope
    }

    if( $InFile )
    {
        $optionalParams['Path'] = Join-Path -Path $TestDrive.FullName -ChildPath $InFile
    }

    Push-Location -Path $InWorkingDirectory
    try
    {
        Remove-GitConfiguration -Name $Name @optionalParams
    }
    finally
    {
        Pop-Location
    }
}

foreach( $level in [Enum]::GetValues([LibGit2Sharp.ConfigurationLevel]) )
{
    if( $level -eq [LibGit2Sharp.ConfigurationLevel]::Xdg -and -not ([LibGit2Sharp.GlobalSettings]::GetConfigSearchPaths($level)) )
    {
        Write-Warning -Message ('Remove-GitConfiguration: unable to test "{0}" scope: looks like there are no XDG-level configuration files so LibGit2Sharp won''t load them. Create these files and reload your PowerShell session.' -f $level)
        continue
    }

    Describe ('Remove-GitConfiguration.when removing from "{0}" scope' -f $level) {
        Init
        GivenConfiguration 'gitautomation.removegitconfiguration' -AtScope $level
        WhenRemoving 'gitautomation.removegitconfiguration' -AtScope $level
        ThenConfiguration 'gitautomation.removegitconfiguration' -Not -Exists
    }

    Describe ('Remove-GitConfiguration.when removing from "{0}" scope and setting does not exist' -f $level) {
        Init
        WhenRemoving 'gitautomation.removegitconfiguration' -AtScope $level
        ThenConfiguration 'gitautomation.removegitconfiguration' -Not -Exists
        ThenError -IsEmpty
    }
}

Describe ('Remove-GitConfiguration.when removing from lower scope but set at higher scope') {
    Init
    GivenConfiguration 'gitautomation.removegitconfiguration' -AtScope Global
    WhenRemoving 'gitautomation.removegitconfiguration' -AtScope Local
    ThenConfiguration 'gitautomation.removegitconfiguration' -Exists
}

Describe ('Remove-GitConfiguration.when removing from local scope but there is no local repository') {
    Init
    WhenRemoving 'gitautomation.removegitconfiguration' -AtScope Local -InWorkingDirectory $TestDrive.FullName -ErrorAction SilentlyContinue
    ThenError -Matches 'there\ is\ no\ Git\ repository'
}

Describe ('Remove-GitConfiguration.when removing at default scope') {
    Init
    GivenConfiguration 'gitautomation.removegitconfiguration' -AtScope Local
    WhenRemoving 'gitautomation.removegitconfiguration'
    ThenConfiguration 'gitautomation.removegitconfiguration' -Not -Exists
}

Describe ('Remove-GitConfiguration.when removing from a specific file') {
    Init
    GivenConfiguration 'gitautomation.removegitconfiguration' -InFile 'mygitconfig'
    WhenRemoving 'gitautomation.removegitconfiguration' -InFile 'mygitconfig'
    ThenConfiguration 'gitautomation.removegitconfiguration' -Not -Exists -InFile 'mygitconfig'
}

[LibGit2Sharp.GlobalSettings]::SetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global, $globalSearchPaths)
