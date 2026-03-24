
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeDiscovery {
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)
}

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:testDirPath = $null
    $script:testNum = 0
    $script:globalSearchPaths =
        [LibGit2Sharp.GlobalSettings]::GetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global)

    function Get-TestRepoPath
    {
        Join-Path -Path $script:testDirPath -ChildPath 'repo'
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
            Set-GitConfiguration -Name $Name `
                                 -Value ([Guid]::NewGuid()) `
                                 -Path (Join-Path -Path $script:testDirPath -ChildPath $InFile)
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
            $optionalParams['Path'] = Join-Path -Path $script:testDirPath -ChildPath $InFile
        }

        Push-Location -Path (Get-TestRepoPath)
        try
        {
            if( $Not )
            {
                Get-GitConfiguration -Name $name @optionalParams | Should -BeNullOrEmpty
            }
            else
            {
                Get-GitConfiguration -Name $name @optionalParams | Should -Not -BeNullOrEmpty
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
            $Global:Error | Should -BeNullOrEmpty
        }

        if( $Matches )
        {
            $Global:Error | Should -Match $Matches
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
            $optionalParams['Path'] = Join-Path -Path $script:testDirPath -ChildPath $InFile
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
}

AfterAll {
    [LibGit2Sharp.GlobalSettings]::SetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global, $script:globalSearchPaths)
}

Describe 'Remove-GitConfiguration' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testDirPath -ItemType Directory

        New-GitRepository -Path (Get-TestRepoPath)

        foreach( $setting in (Get-GitConfiguration | Where-Object { $_.Key -like 'gitautomation.*' }) )
        {
            Remove-GitConfiguration -Name $setting.Key -Scope $setting.Level
        }

        $Global:Error.Clear()
    }

    function Test-CfgPermission
    {
        param(
            [LibGit2Sharp.ConfigurationLevel]$Scope
        )

        $globalScopes = @([LibGit2Sharp.ConfigurationLevel]::ProgramData,[LibGit2Sharp.ConfigurationLevel]::System)
        if ($scope -notin $globalScopes)
        {
            return $true
        }

        $cfgDirPaths = [LibGit2Sharp.GlobalSettings]::GetConfigSearchPaths($Scope)
        if (-not $cfgDirPaths)
        {
            $msg = "[$($PSCommandPath | Split-Path -Leaf)]  Skipping tests for ${Scope} scope because there are no " +
                   'configured directories at that scope on this system.'
            Write-Warning $msg
            return $false
        }

        foreach ($cfgDirPath in $cfgDirPaths)
        {
            $testFilePath = Join-Path -Path $cfgDirPath -ChildPath '.gitautomation'

            $canModify = $false
            try
            {
                New-Item -Path $testFilePath -ItemType File -Force -ErrorAction Ignore
            }
            finally
            {
                if (Test-Path -Path $testFilePath)
                {
                    $canModify = $true
                    Remove-Item -Path $testFilePath -Force -ErrorAction Ignore
                }
            }

            if ($canModify)
            {
                break
            }
        }

        if (-not $canModify)
        {
            $msg = "[$($PSCommandPath | Split-Path -Leaf)]  Skipping tests for ${Scope} scope because you don't have " +
                   "permission to write to config files in ""$($testFilePath | Split-Path -Parent)"". To run these " +
                   'tests, run PowerShell as administrator.'
            Write-Warning $msg
        }

        return $canModify
    }

    $cfg = [LibGit2Sharp.Configuration]::BuildFrom([NullString]::Value)

    $scopes = [Enum]::GetValues([LibGit2Sharp.ConfigurationLevel])
    Context "<_> scope" -ForEach $scopes {

        $scope = $_
        $hasCfgAtScope = $cfg.HasConfig($scope)
        $hasCfgDir = $false
        try
        {
            if ([LibGit2Sharp.GlobalSettings]::GetConfigSearchPaths($scope))
            {
                $hasCfgDir = $true
            }
        }
        catch
        {
        }
        $canWriteCfg = Test-CfgPermission -Scope $scope
        $skip = -not $canWriteCfg

        if ($hasCfgAtScope -or $Scope -eq [LibGit2Sharp.ConfigurationLevel]::Local)
        {
            It 'removes' -ForEach $scope -Skip:$skip {
                GivenConfiguration 'gitautomation.removegitconfiguration' -AtScope $_
                WhenRemoving 'gitautomation.removegitconfiguration' -AtScope $_
                ThenConfiguration 'gitautomation.removegitconfiguration' -Not -Exists
            }

            It 'handles missing setting' -ForEach $_ {
                WhenRemoving 'gitautomation.removegitconfiguration' -AtScope $_
                ThenConfiguration 'gitautomation.removegitconfiguration' -Not -Exists
                ThenError -IsEmpty
            }
        }
        elseif ($hasCfgDir)
        {
            It 'writes an error' -ForEach $scope {
                { WhenRemoving 'gitautomation.removegitconfiguration' -AtScope $_ } |
                    Should -Throw "*No ${_} configuration file*"
                ThenConfiguration 'gitautomation.removegitconfiguration' -Not -Exists
            }
        }
        elseif ($scope -eq [LibGit2Sharp.ConfigurationLevel]::Worktree)
        {
            It 'fails' -ForEach $scope {
                { WhenRemoving 'gitautomation.removegitconfiguration' -AtScope $_ } |
                    Should -Throw "*invalid config path selector*"
                ThenConfiguration 'gitautomation.removegitconfiguration' -Not -Exists
            }
        }
        else
        {
            It 'writes an error' -ForEach $scope {
                WhenRemoving 'gitautomation.removegitconfiguration' -AtScope $_ -ErrorAction SilentlyContinue
                ThenConfiguration 'gitautomation.removegitconfiguration' -Not -Exists
                ThenError -Matches "\b${_}\b.*no directories are configured"
            }
        }
    }

    It 'removes from lower scope but set at higher scope' {
        GivenConfiguration 'gitautomation.removegitconfiguration' -AtScope Global
        WhenRemoving 'gitautomation.removegitconfiguration' -AtScope Local
        ThenConfiguration 'gitautomation.removegitconfiguration' -Exists
    }

    It 'removes from local scope but there is no local repository' {
        WhenRemoving 'gitautomation.removegitconfiguration' `
                     -AtScope Local `
                     -InWorkingDirectory $script:testDirPath `
                     -ErrorAction SilentlyContinue
        ThenError -Matches 'there\ is\ no\ Git\ repository'
    }

    It 'removes at default scope' {
        GivenConfiguration 'gitautomation.removegitconfiguration' -AtScope Local
        WhenRemoving 'gitautomation.removegitconfiguration'
        ThenConfiguration 'gitautomation.removegitconfiguration' -Not -Exists
    }

    It 'removes from a specific file' {
        GivenConfiguration 'gitautomation.removegitconfiguration' -InFile 'mygitconfig'
        WhenRemoving 'gitautomation.removegitconfiguration' -InFile 'mygitconfig'
        ThenConfiguration 'gitautomation.removegitconfiguration' -Not -Exists -InFile 'mygitconfig'
    }
}
