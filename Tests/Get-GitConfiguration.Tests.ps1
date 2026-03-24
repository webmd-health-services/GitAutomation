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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:testDirPath = $null
    $script:testNum = 0
    $script:globalSearchPaths =
        [LibGit2Sharp.GlobalSettings]::GetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global)
    $script:result = $null

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
            Set-GitConfiguration -Name $Named -Value $HasValue -Path (Join-Path -Path $script:testDirPath -ChildPath $InFile)
        }
    }

    function GivenFile
    {
        param(
            $Named,
            $Content
        )

        $Content | Set-Content -Path (Join-Path -Path $script:testDirPath -ChildPath $Named)
    }

    function GivenRepository
    {
        param(
            $At
        )

        New-GitRepository -Path (Join-Path -Path $script:testDirPath -ChildPath $At)
    }

    function ThenFile
    {
        param(
            $Named,

            [Parameter(Mandatory)]
            [Switch]
            $Exists
        )

        Join-Path -Path $script:testDirPath -ChildPath $Named | Should -Exist
    }

    function ThenValue
    {
        param(
            [Parameter(Mandatory,ParameterSetName='Is')]
            $Is,

            [Parameter(Mandatory,ParameterSetName='IsNull')]
            [Switch]
            $IsNull,

            [Parameter(Mandatory,ParameterSetName='Contains')]
            $Contains,

            [Parameter(Mandatory,ParameterSetName='Contains')]
            $WithValue

        )

        if( $IsNull )
        {
            $script:result | Should -BeNullOrEmpty
        }

        if( $Is )
        {
            $script:result | Should -Not -BeNullOrEmpty
            $script:result.Value | Should -Be $Is
        }

        if( $Contains )
        {
            $script:result |
                ForEach-Object { $_ } |
                Where-Object { $_.Key -eq $Contains -and $_.Value -eq $WithValue } |
                Should -Not -BeNullOrEmpty
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
            $optionalParams['Path'] = Join-Path -Path $script:testDirPath -ChildPath $FromFile
        }

        if( $InRepo )
        {
            $optionalParams['RepoRoot'] = Join-Path -Path $script:testDirPath -ChildPath $InRepo
        }

        if( $AtScope )
        {
            $optionalParams['Scope'] = $AtScope
        }

        if( $InWorkingDirectory )
        {
            Push-Location -Path (Join-Path -Path $script:testDirPath -ChildPath $InWorkingDirectory -Resolve)
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
}

AfterAll {
    [LibGit2Sharp.GlobalSettings]::SetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global, $globalSearchPaths)
}

Describe 'Get-GitConfiguration' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testDirPath -ItemType Directory
        $script:result = $null
    }

    It 'gets configuration from a specific file' {
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

    It 'gets configuration from a file that doesn''t exist' {
        WhenGettingConfiguration 'user.name' -FromFile 'config'
        ThenValue -IsNull
        ThenFile 'config' -Exists
    }

    It 'gets repository configuration' {
        GivenRepository 'repo'
        GivenFile 'repo\.git\config' @'
    [fubar]
        snafu = fizzbuzz
'@
        WhenGettingConfiguration 'fubar.snafu' -InRepo 'repo'
        ThenValue -Is 'fizzbuzz'
    }

    It 'gets repository configuration when in a repository' {
        GivenRepository 'repo'
        GivenFile 'repo\.git\config' @'
    [fubar]
        snafu = fizzbuzz
'@
        WhenGettingConfiguration 'fubar.snafu' -InWorkingDirectory 'repo'
        ThenValue -Is 'fizzbuzz'
    }

    It 'gets global configuration' {
        $value = [Guid]::NewGuid()
        GivenConfiguration 'fubar.snafu' -HasValue $value -AtScope Global
        WhenGettingConfiguration 'fubar.snafu'
        ThenValue -Is $value
    }

    It 'gets system configuration from inside a repository' {
        $value = [Guid]::NewGuid()
        GivenRepository 'repo'
        GivenConfiguration 'fubar.snafu' -HasValue $value -AtScope System
        WhenGettingConfiguration 'fubar.snafu' -InWorkingDirectory 'repo'
        ThenValue -Is $value
    }

    It 'gets system configuration from outside a repository' {
        $value = [Guid]::NewGuid()
        GivenConfiguration 'fubar.snafu' -HasValue $value -AtScope System
        Push-Location $script:testDirPath
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

    It 'gets all configuration in a specific file' {
        $value1 = [Guid]::NewGuid()
        $value2 = [guid]::NewGuid()
        GivenConfiguration -Named 'fubar.value1' -HasValue $value1 -InFile 'config'
        GivenConfiguration -Named 'fubar.value2' -HasValue $value2 -InFile 'config'
        WhenGettingConfiguration -FromFile 'config'
        ThenValue -Contains 'fubar.value1' -WithValue $value1
        ThenValue -Contains 'fubar.value2' -WithValue $value2
    }

    It 'gets all configuration in a specific file' {
        $local = [Guid]::NewGuid()
        $global = [Guid]::NewGuid()
        $system = [Guid]::NewGuid()
        GivenRepository 'repo'
        GivenConfiguration -Named 'gitautomation.local' -HasValue $local -InFile 'repo\.git\config'
        GivenConfiguration -Named 'gitautomation.local' -HasValue $system -AtScope System
        GivenConfiguration -Named 'gitautomation.local' -HasValue $global -AtScope Global
        WhenGettingConfiguration -InRepo 'repo'
        ThenValue -Contains 'gitautomation.local' -WithValue $local
        WhenGettingConfiguration -InWorkingDirectory '.'
        ThenValue -Contains 'gitautomation.local' -WithValue $global
    }
}
