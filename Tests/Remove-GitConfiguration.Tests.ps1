
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

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
    }

    $levels = [Enum]::GetValues([LibGit2Sharp.ConfigurationLevel])
    Context "<_> scope" -ForEach $levels {

        $level = $_

        if( $level -eq [LibGit2Sharp.ConfigurationLevel]::Xdg -and `
            -not ([LibGit2Sharp.GlobalSettings]::GetConfigSearchPaths($level)) )
        {
            $msg = "Remove-GitConfiguration: unable to test ""${level}"" scope: looks like there are no XDG-level " +
                   'configuration files so LibGit2Sharp won''t load them. Create these files and reload your ' +
                   'PowerShell session.'
            Write-Warning -Message $msg
            continue
        }

        It 'removes' -ForEach $level {
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
