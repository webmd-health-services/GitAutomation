
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:testDirPath = $null
    $script:testNum = 0
    $script:remoteRepoRoot = $null
    $script:remoteWorkingRoot = $null
    $script:localRoot = $null

    function GivenBranch
    {
        param(
            [string]
            $Name,

            [Switch]
            $InRemote,

            [Switch]
            $InLocal
        )

        if( $InRemote )
        {
            $repoRoot = $script:remoteWorkingRoot
        }
        else
        {
            $repoRoot = $script:localRoot
        }

        New-GitBranch -RepoRoot $repoRoot -Name $Name | Out-Null

        if( $InRemote )
        {
            Send-GitCommit -RepoRoot $repoRoot
        }
    }

    function GivenCommit
    {
        param(
            [Switch]
            $InRemote,

            [Switch]
            $InLocal,

            [string]
            $OnBranch
        )

        if( $InRemote )
        {
            $repoRoot = $script:remoteWorkingRoot
            $prefix = 'remote'
        }
        else
        {
            $repoRoot = $script:localRoot
            $prefix = 'local'
        }

        if( $OnBranch )
        {
            Update-GitRepository -RepoRoot $repoRoot -Revision $OnBranch | Out-Null
        }

        $filename = '{0}-{1}' -f $prefix,[IO.Path]::GetRandomFileName()
        Add-GitTestFile -RepoRoot $repoRoot -Path $filename | Out-Null
        Add-GitItem -RepoRoot $repoRoot -Path $filename
        Save-GitCommit -RepoRoot $repoRoot -Message $filename

        if( $InRemote )
        {
            Send-GitCommit -RepoRoot $script:remoteWorkingRoot | Out-Null
        }
    }

    function GivenLocalRepoIs
    {
        param(
            [Switch]
            $ClonedFromRemote,

            [Switch]
            $Standalone
        )

        $script:localRoot =
            Join-Path -Path $script:testDirPath -ChildPath ('Local.{0}' -f [IO.Path]::GetRandomFileName())
        if( $ClonedFromRemote )
        {
            Copy-GitRepository -Source $script:remoteRepoRoot -DestinationPath $script:localRoot
        }
        else
        {
            New-GitRepository -Path $script:localRoot
        }
    }

    function ThenNoErrorsWereThrown
    {
        param(
        )

        $Global:Error | Should -BeNullOrEmpty
    }

    function ThenErrorWasThrown
    {
        param(
            [string]
            $ErrorMessage
        )

        $Global:Error | Should -Match $ErrorMessage
    }

    function ThenLocalHead
    {
        param(
            $CanonicalName,
            $Tracks
        )

        $repo = Get-GitRepository -RepoRoot $script:localRoot
        try
        {
            [LibGit2Sharp.Branch]$localHead = $repo.Branches | Where-Object { $_.CanonicalName -eq $CanonicalName }
            $localHead | Should -Not -BeNullOrEmpty
            $localHead.IsTracking | Should -Be $true
            $localHead.TrackedBranch.CanonicalName | Should -Be $Tracks
        }
        finally
        {
            $repo.Dispose()
        }
    }

    function ThenRemoteRevision
    {
        param(
            [string]
            $Revision,

            [Switch]
            $Exists,

            [Switch]
            $DoesNotExist
        )

        $commitExists = Test-GitCommit -RepoRoot $script:remoteRepoRoot -Revision $Revision
        if( $Exists )
        {
            $commitExists | Should -BeTrue
        }
        else
        {
            $commitExists | Should -BeFalse
        }
    }

    function ThenPushResultIs
    {
        param(
            $PushStatus
        )

        $script:pushResult | Should -Be $PushStatus
    }

    function WhenSendingCommits
    {
        [CmdletBinding()]
        param(
            [Switch]
            $SetUpstream
        )

        $Global:Error.Clear()
        $script:pushResult = $null

        $script:pushResult = Send-GitCommit -RepoRoot $script:localRoot -SetUpstream:$SetUpstream #-ErrorAction SilentlyContinue
    }
}

Describe 'Send-GitCommit' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testDirPath -ItemType Directory

        $script:remoteRepoRoot = Join-Path -Path $script:testDirPath -ChildPath 'Remote.Bare'
        New-GitRepository -Path $script:remoteRepoRoot -Bare

        $script:remoteWorkingRoot = Join-Path -Path $script:testDirPath -ChildPath 'Remote.Working'
        Copy-GitRepository -Source $script:remoteRepoRoot -DestinationPath $script:remoteWorkingRoot

        Add-GitTestFile -RepoRoot $script:remoteWorkingRoot -Path 'InitialCommit.txt'
        Add-GitItem -RepoRoot $script:remoteWorkingRoot -Path 'InitialCommit.txt'
        Save-GitCommit -RepoRoot $script:remoteWorkingRoot -Message 'Initial Commit'
        Send-GitCommit -RepoRoot $script:remoteWorkingRoot
    }

    It 'pushing changes to a remote repository' {
        GivenLocalRepoIs -ClonedFromRemote
        $commit = GivenCommit -InLocal
        WhenSendingCommits
        ThenNoErrorsWereThrown
        ThenPushResultIs ([Git.Automation.PushResult]::Ok)
        ThenRemoteRevision $commit.Sha -Exists
    }

    It 'there are no local changes to push to remote' {
        GivenLocalRepoIs -ClonedFromRemote
        WhenSendingCommits
        ThenNoErrorsWereThrown
        ThenPushResultIs ([Git.Automation.PushResult]::Ok)
    }

    It 'remote repository has changes not contained locally' {
        GivenLocalRepoIs -ClonedFromRemote
        GivenCommit -InRemote
        GivenCommit -InLocal
        WhenSendingCommits -ErrorAction SilentlyContinue
        ThenErrorWasThrown 'that you are trying to update on the remote contains commits that are not present locally.'
        ThenPushResultIs ([Git.Automation.PushResult]::Rejected)
    }

    It 'no upstream remote is defined' {
        GivenLocalRepoIs -Standalone
        GivenCommit -InLocal
        WhenSendingCommits -ErrorAction SilentlyContinue
        ThenErrorWasThrown 'A\ remote\ named\ "origin"\ does\ not\ exist\.'
        ThenPushResultIs ([Git.Automation.PushResult]::Failed)
    }

    It 'changes on other branches' {
        GivenBranch 'develop' -InRemote
        GivenCommit -InRemote -OnBranch 'develop'
        GivenLocalRepoIs -ClonedFromRemote
        $masterCommit = GivenCommit -InLocal -OnBranch 'master'
        $developCommit = GivenCommit -InLocal -OnBranch 'develop'
        WhenSendingCommits
        ThenRemoteRevision $masterCommit.Sha -DoesNotExist
        ThenRemoteRevision $developCommit.Sha -Exists
    }

    It 'pushing a new branch' {
        GivenLocalRepoIs -ClonedFromRemote
        GivenBranch 'develop' -InLocal
        $commit = GivenCommit -InLocal
        WhenSendingCommits -SetUpstream
        ThenPushResultIs ([Git.Automation.PushResult]::Ok)
        ThenRemoteRevision $commit.Sha -Exists
        ThenRemoteRevision 'develop' -Exists
        ThenLocalHead 'refs/heads/develop' -Tracks 'refs/remotes/origin/develop'
    }

    It 'pushing new commits on a branch' {
        GivenBranch 'develop' -InRemote
        GivenCommit -InRemote -OnBranch 'develop'
        GivenLocalRepoIs -ClonedFromRemote
        $commit = GivenCommit -InLocal -OnBranch 'develop'
        WhenSendingCommits
        ThenPushResultIs ([Git.Automation.PushResult]::Ok)
        ThenRemoteRevision $commit.Sha -Exists
        ThenRemoteRevision 'develop' -Exists
    }
}