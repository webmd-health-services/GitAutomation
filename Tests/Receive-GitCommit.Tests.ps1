
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:testDirPath = $null
    $script:testNum = 0
}

Describe 'Receive-GitCommit'{
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testDirPath -ItemType Directory
        $Global:Error.Clear()
    }

    It 'pulls commits' {
        $remoteRepo = Join-Path -Path $script:testDirPath -ChildPath 'RemoteRepo'
        New-GitRepository -Path $remoteRepo
        Add-GitTestFile -RepoRoot $remoteRepo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file1') -RepoRoot $remoteRepo
        Save-GitCommit -RepoRoot $remoteRepo -Message 'file1 commit'

        $localRepoPath = Join-Path -Path $script:testDirPath -ChildPath 'LocalRepo'
        Copy-GitRepository -Source $remoteRepo -DestinationPath $localRepoPath

        Add-GitTestFile -RepoRoot $remoteRepo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file2') -RepoRoot $remoteRepo
        Save-GitCommit -RepoRoot $remoteRepo -Message 'file2 commit'

        $repo = Find-GitRepository -Path $localRepoPath
        $remote = Find-GitRepository -Path $remoteRepo
        try
        {
            $repo.Head.Tip.Sha | Should -Not -Be $remote.Head.Tip.Sha
            Receive-GitCommit -RepoRoot $localRepoPath

            [LibGit2Sharp.Branch]$remoteOrigin = $repo.Branches | Where-Object { $_.FriendlyName -eq 'origin/master' }
            [LibGit2Sharp.Branch]$localOrigin = $repo.Branches | Where-Object { $_.FriendlyName -eq 'master' }
            $remoteOrigin.Tip.Sha | Should -Not -Be $localOrigin.Tip.Sha

            $repo.Head.Tip.Sha | Should -Not -Be $remote.Head.Tip.Sha
        }
        finally
        {
            $repo.Dispose()
            $remote.Dispose()
        }

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'the given repo doesn''t exist' {
        Receive-GitCommit -RepoRoot 'C:\I\do\not\exist' -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'does not exist'
    }
}