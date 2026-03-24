

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)
}

Describe 'Test-GitTag' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'running from a valid git repository'{
        $repo = Join-Path -Path $TestDrive -ChildPath '1'
        New-GitRepository -Path $repo

        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        New-GitTag -RepoRoot $repo -Name 'tip'

        Test-GitTag -RepoRoot $repo -Name 'tip' | Should -BeTrue

        Test-GitTag -RepoRoot $repo -Name 'whocares' | Should -BeFalse

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'running from an invalid git repository'{
        Test-GitTag -RepoRoot 'C:\I\do\not\exist' -Name 'whocares' -ErrorAction SilentlyContinue

        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'does not exist'
    }
}