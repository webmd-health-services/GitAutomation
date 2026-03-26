
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:testDirPath = $null
    $script:testNum = 0
}

Describe 'Test-GitBranch' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testDirPath -ItemType Directory

        $Global:Error.Clear()
    }

    It 'running from a valid git repository' {
        $repo = Join-Path -Path $script:testDirPath -ChildPath 'repo'
        New-GitRepository -Path $repo

        Add-GitTestFile -RepoRoot $repo -Path 'file1'

        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Test-GitBranch -RepoRoot $repo -Name 'master' | Should -BeTrue

        Test-GitBranch -RepoRoot $repo -Name 'whocares' | Should -BeFalse

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'passed an invalid repository' {
        Test-GitBranch -RepoRoot 'C:\I\do\not\exist' -Name 'whocares' -ErrorAction SilentlyContinue

        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'does not exist'
    }
}