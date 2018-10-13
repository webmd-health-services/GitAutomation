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
[LibGit2Sharp.ConfigurationEntry[string]]$result = $null

function GivenConfiguration
{
    param(
        $Named,
        $HasValue,
        $AtScope
    )


    $config = [LibGit2Sharp.Configuration]::BuildFrom([nullstring]::Value,[nullstring]::Value)
    $config.Unset($Named, [LibGit2Sharp.ConfigurationLevel]::Global)
    $config.Dispose()
    
    Set-GitConfiguration -Name $Named -Value $HasValue -Scope $AtScope
}

function GivenFile
{
    param(
        $Named,
        $Content
    )

    $Content | Set-Content -Path (Join-Path -Path $TestDrive.FullName -ChildPath $Named)
}

function GivenRepository
{
    param(
        $At
    )

    New-GitRepository -Path (Join-Path -Path $TestDrive.FullName -ChildPath $At)
}

function Init
{
    $script:result = $null
}

function ThenFile
{
    param(
        $Named,

        [Parameter(Mandatory)]
        [Switch]
        $Exists
    )

    It ('should create configuration file') {
        Join-Path -Path $TestDrive.FullName -ChildPath $Named | Should -Exist
    }
}

function ThenValueIs
{
    param(
        $ExpectedValue
    )

    if( $ExpectedValue -eq $null )
    {
        It ('should return nothing') {
            $result | Should -BeNullOrEmpty
        }
    }
    else
    {
        It ('should return the expected value') {
            $result | Should -Not -BeNullOrEmpty
            $result.Value | Should -Be $ExpectedValue
        }
    }
}

function WhenGettingConfiguration
{
    [CmdletBinding(DefaultParameterSetName='Default')]
    param(
        [Parameter(Mandatory,Position=0)]
        $Named,

        [Parameter(Mandatory,ParameterSetName='FromFile')]
        $FromFile,

        [Parameter(Mandatory,ParameterSetName='InRepo')]
        $InRepo,

        [Parameter(Mandatory,ParameterSetName='InWorkingDirectory')]
        $InWorkingDirectory,

        [Parameter()]
        $AtScope
    )

    $optionalParams = @{ }

    if( $FromFile )
    {
        $optionalParams['Path'] = Join-Path -Path $TestDrive.FullName -ChildPath $FromFile
    }

    if( $InRepo )
    {
        $optionalParams['RepoRoot'] = Join-Path -Path $TestDrive.FullName -ChildPath $InRepo
    }

    if( $AtScope )
    {
        $optionalParams['Scope'] = $AtScope
    }

    if( $InWorkingDirectory )
    {
        Push-Location -Path (Join-Path -Path $TestDrive.FullName -ChildPath $InWorkingDirectory)
    }

    try
    {
        $script:result = Get-GitConfiguration -Name $Named @optionalParams
    }
    finally
    {
        if( $InWorkingDirectory )
        {
            Pop-Location
        }
    }
}

Describe 'Get-GitConfiguration.when getting configuration from a specific file' {
    Init
    GivenFile 'config' @'
[user]
    name = Fubar
    email = fubar@example.com
'@
    WhenGettingConfiguration 'user.name' -FromFile 'config'
    ThenValueIs 'Fubar'
    WhenGettingConfiguration 'user.email' -FromFile 'config'
    ThenValueIs 'fubar@example.com'
}

Describe 'Get-GitConfiguration.when getting configuration from a file that doesn''t exist' {
    Init
    WhenGettingConfiguration 'user.name' -FromFile 'config'
    ThenValueIs $null
    ThenFile 'config' -Exists
}

Describe 'Get-GitConfiguration.when getting repository configuration' {
    Init
    GivenRepository 'repo'
    GivenFile 'repo\.git\config' @'
[fubar]
    snafu = fizzbuzz
'@
    WhenGettingConfiguration 'fubar.snafu' -InRepo 'repo'
    ThenValueIs 'fizzbuzz'
}

Describe 'Get-GitConfiguration.when getting repository configuration when in a repository' {
    Init
    GivenRepository 'repo'
    GivenFile 'repo\.git\config' @'
[fubar]
    snafu = fizzbuzz
'@
    WhenGettingConfiguration 'fubar.snafu' -InWorkingDirectory 'repo'
    ThenValueIs 'fizzbuzz'
}

Describe 'Get-GitConfiguraiton.when getting global configuration' {
    $value = [Guid]::NewGuid()
    Init
    GivenConfiguration 'fubar.snafu' -HasValue $value -AtScope Global
    WhenGettingConfiguration 'fubar.snafu' -AtScope Global
    ThenValueIs $value
}

Describe 'Get-GitConfiguraiton.when getting system configuration from inside a repository' {
    $value = [Guid]::NewGuid()
    Init
    GivenRepository 'repo'
    GivenConfiguration 'fubar.snafu' -HasValue $value -AtScope System
    WhenGettingConfiguration 'fubar.snafu' -InWorkingDirectory 'repo'
    ThenValueIs $value
}

Describe 'Get-GitConfiguraiton.when getting system configuration from outside a repository' {
    $value = [Guid]::NewGuid()
    Init
    GivenConfiguration 'fubar.snafu' -HasValue $value -AtScope System
    Push-Location $TestDrive.FullName
    try
    {
        WhenGettingConfiguration 'fubar.snafu' 
    }
    finally
    {
        Pop-Location
    }
    ThenValueIs $value
}

[LibGit2Sharp.GlobalSettings]::SetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global, $globalSearchPaths)