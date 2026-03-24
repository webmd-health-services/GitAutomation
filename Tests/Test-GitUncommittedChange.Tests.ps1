
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)
}

Describe 'Test-GitUncommittedChange' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'checking for uncommitted changes'{
        $repo = Join-Path -Path $TestDrive -ChildPath '1'
        New-GitRepository -Path $repo

        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        Save-GitCommit -RepoRoot $repo -Message 'added file1'

        Test-GitUncommittedChange -RepoRoot $repo | Should -BeFalse

        '' | Set-Content -Path (Join-Path -Path $repo -ChildPath 'file1')

        Test-GitUncommittedChange -RepoRoot $repo | Should -BeTrue

        Add-GitItem -Path (Join-Path $repo -ChildPath 'file1') -RepoRoot $repo
        Save-GitCommit -RepoRoot $repo -Message 'modified file1'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo

        Test-GitUncommittedChange -RepoRoot $repo | Should -BeTrue

        Save-GitCommit -RepoRoot $repo -Message 'added file2'

        Rename-Item -Path (Join-Path -Path $repo -ChildPath 'file2') -NewName 'file2.Awesome'

        Test-GitUncommittedChange -RepoRoot $repo | Should -BeTrue

        Add-GitItem -Path (Join-Path $repo -ChildPath 'file2.Awesome') -RepoRoot $repo
        Save-GitCommit -RepoRoot $repo -Message 'renamed file2'

        Remove-Item -Path (Join-Path -Path $repo -ChildPath 'file1')

        Test-GitUncommittedChange -RepoRoot $repo | Should -BeTrue

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'the given repo doesn''t exist' {
        Test-GitUncommittedChange -RepoRoot 'C:\I\do\not\exist' -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'does not exist'
    }
}