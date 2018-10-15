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
$result = $null

function GivenConfiguration
{
    param(
        [Parameter(Mandatory,Position=0)]
        $Named,
        $HasValue,
        [Parameter(Mandatory,ParameterSetName='AtScope')]
        $AtScope,
        [Parameter(Mandatory,ParameterSetName='InFile')]
        $InFile
    )


    $config = [LibGit2Sharp.Configuration]::BuildFrom([nullstring]::Value,[nullstring]::Value)
    $config.Unset($Named, [LibGit2Sharp.ConfigurationLevel]::Global)
    $config.Dispose()
    
    if( $AtScope )
    {
        Set-GitConfiguration -Name $Named -Value $HasValue -Scope $AtScope
    }

    if( $InFile )
    {
        Set-GitConfiguration -Name $Named -Value $HasValue -Path (Join-Path -Path $TestDrive.FullName -ChildPath $InFile)
    }        
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

function ThenValue
{
    param(
        [Parameter(Mandatory,ParameterSetName='Is')]
        [AllowNull()]
        $Is,

        [Parameter(Mandatory,ParameterSetName='Contains')]
        $Contains,
        
        [Parameter(Mandatory,ParameterSetName='Contains')]
        $WithValue
        
    )

    if( $Is )
    {
        if( $Is -eq $null )
        {
            It ('should return nothing') {
                $result | Should -BeNullOrEmpty
            }
        }
        else
        {
            It ('should return the expected value') {
                $result | Should -Not -BeNullOrEmpty
                $result.Value | Should -Be $Is
            }
        }
    }

    if( $Contains )
    {
        It ('should return multiple results') {
            $result | 
                ForEach-Object { $_ } |
                Where-Object { $_.Key -eq $Contains -and $_.Value -eq $WithValue } | 
                Should -Not -BeNullOrEmpty
        }
    }
}

function WhenGettingConfiguration
{
    [CmdletBinding(DefaultParameterSetName='Default')]
    param(
        [Parameter(Position=0)]
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
        Push-Location -Path (Join-Path -Path $TestDrive.FullName -ChildPath $InWorkingDirectory -Resolve)
    }

    if( $Named )
    {
        $optionalParams['Name'] = $Named
    }

    try
    {
        $script:result = Get-GitConfiguration @optionalParams
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
    ThenValue -Is 'Fubar'
    WhenGettingConfiguration 'user.email' -FromFile 'config'
    ThenValue -Is 'fubar@example.com'
}

Describe 'Get-GitConfiguration.when getting configuration from a file that doesn''t exist' {
    Init
    WhenGettingConfiguration 'user.name' -FromFile 'config'
    ThenValue -Is $null
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
    ThenValue -Is 'fizzbuzz'
}

Describe 'Get-GitConfiguration.when getting repository configuration when in a repository' {
    Init
    GivenRepository 'repo'
    GivenFile 'repo\.git\config' @'
[fubar]
    snafu = fizzbuzz
'@
    WhenGettingConfiguration 'fubar.snafu' -InWorkingDirectory 'repo'
    ThenValue -Is 'fizzbuzz'
}

Describe 'Get-GitConfiguraiton.when getting global configuration' {
    $value = [Guid]::NewGuid()
    Init
    GivenConfiguration 'fubar.snafu' -HasValue $value -AtScope Global
    WhenGettingConfiguration 'fubar.snafu' -AtScope Global
    ThenValue -Is $value
}

Describe 'Get-GitConfiguraiton.when getting system configuration from inside a repository' {
    $value = [Guid]::NewGuid()
    Init
    GivenRepository 'repo'
    GivenConfiguration 'fubar.snafu' -HasValue $value -AtScope System
    WhenGettingConfiguration 'fubar.snafu' -InWorkingDirectory 'repo'
    ThenValue -Is $value
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
    ThenValue -Is $value
}

Describe 'Get-GitConfiguration.when getting all configuration in a specific file' {
    $value1 = [Guid]::NewGuid()
    $value2 = [guid]::NewGuid()
    Init
    GivenConfiguration -Named 'fubar.value1' -HasValue $value1 -InFile 'config'
    GivenConfiguration -Named 'fubar.value2' -HasValue $value2 -InFile 'config'
    WhenGettingConfiguration -FromFile 'config'
    ThenValue -Contains 'fubar.value1' -WithValue $value1
    ThenValue -Contains 'fubar.value2' -WithValue $value2
}


Describe 'Get-GitConfiguration.when getting all configuration in a specific file' {
    $local = [Guid]::NewGuid()
    $global = [Guid]::NewGuid()
    $system = [Guid]::NewGuid()
    Init
    GivenRepository 'repo'
    GivenConfiguration -Named 'gitautomation.local' -HasValue $local -InFile 'repo\.git\config'
    GivenConfiguration -Named 'gitautomation.local' -HasValue $system -AtScope System
    GivenConfiguration -Named 'gitautomation.local' -HasValue $global -AtScope Global
    WhenGettingConfiguration -InRepo 'repo'
    ThenValue -Contains 'gitautomation.local' -WithValue $local
    WhenGettingConfiguration -InWorkingDirectory '.'
    ThenValue -Contains 'gitautomation.local' -WithValue $global
}

[LibGit2Sharp.GlobalSettings]::SetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global, $globalSearchPaths)