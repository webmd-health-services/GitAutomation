
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)
}

Describe 'Test-GitRemoteUri'{
    It 'returns true for a valid remote'{
        $remoteRepo = New-GitTestRepo
        $localRepoPath = Join-Path -Path (Resolve-TestDrivePath) -ChildPath 'LocalRepo'
        Copy-GitRepository -Source $remoteRepo -DestinationPath $localRepoPath
        $repo = Find-GitRepository -Path $localRepoPath

        $configPath = Join-Path $localRepoPath .git/config
        $url = Get-Content $configPath | Where-Object { $_ -match 'url = .*' } | ForEach-Object { $_.ToString().Remove(0,7)}
        Test-GitRemoteUri -Uri $url | Should -BeTrue
    }

    It 'returns false for an invalid uri'{
        Test-GitRemoteUri -Uri 'ssh://git@github.com:webmd-health-services/IDoNotExist.git' | Should -BeFalse
    }
}