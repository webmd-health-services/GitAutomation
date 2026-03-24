
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:testDirPath = $null
    $script:testNum = 0

    function GivenRemoteRepository
    {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $Path
        )

        $script:remoteRepoPath = (Join-Path -Path $script:testDirPath -ChildPath $Path)
        New-GitRepository -Path $remoteRepoPath | Out-Null
        Add-GitTestFile -RepoRoot $remoteRepoPath -Path 'InitialCommit.txt'
        Add-GitItem -RepoRoot $remoteRepoPath -Path 'InitialCommit.txt'
        Save-GitCommit -RepoRoot $remoteRepoPath -Message 'Initial Commit'
        Set-GitConfiguration -Name 'core.bare' -Value 'true' -RepoRoot $remoteRepoPath
    }

    function GivenLocalRepositoryTracksRemote
    {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $Path
        )

        $script:localRepoPath = (Join-Path -Path $script:testDirPath -ChildPath $Path)
        Copy-GitRepository -Source $remoteRepoPath -DestinationPath $localRepoPath
    }

    function GivenLocalRepositoryWithNoRemote
    {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $Path
        )

        $script:localRepoPath = (Join-Path -Path $script:testDirPath -ChildPath $Path)
        New-GitRepository -Path $localRepoPath | Out-Null
    }

    function GivenTag
    {
        param(
            $Name
        )

        New-GitTag -RepoRoot $localRepoPath -Name $Name -Force
    }

    function GivenCommit
    {
        $fileName = [IO.Path]::GetRandomFileName()
        Add-GitTestFile -RepoRoot $localRepoPath -Path $fileName | Out-Null
        Add-GitItem -RepoRoot $localRepoPath -Path $fileName
        Save-GitCommit -RepoRoot $localRepoPath -Message $fileName
    }

    function GivenRemoteContainsOtherChanges
    {
        Set-GitConfiguration -Name 'core.bare' -Value 'false' -RepoRoot $remoteRepoPath
        Add-GitTestFile -RepoRoot $remoteRepoPath -Path 'RemoteTestFile.txt'
        Add-GitItem -RepoRoot $remoteRepoPath -Path 'RemoteTestFile.txt'
        Save-GitCommit -RepoRoot $remoteRepoPath -Message 'Adding remote test file to remote repo'
        Set-GitConfiguration -Name 'core.bare' -Value 'true' -RepoRoot $remoteRepoPath
    }

    function ThenNoErrorsWereThrown
    {
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

    function ThenRemoteContainsLocalCommits
    {
        Test-GitUncommittedChange -RepoRoot $localRepoPath | Should -BeFalse

        $repo = Get-GitRepository -RepoRoot $localRepoPath
        try
        {
            $localBranch = $repo.Branches | Where-Object { $_.IsCurrentRepositoryHead -and -not $_.IsRemote }
            $remoteBranch =
                $repo.Branches | Where-Object { $_.IsRemote -and $_.CanonicalName -eq $localBranch.TrackedBranch }
            $localBranch | Should -Not -BeNullOrEmpty
            $remoteBranch | Should -Not -BeNullOrEmpty
            $remoteBranch.Tip | Should -Be $localBranch.Tip
        }
        finally
        {
            $repo.Dispose()
        }

        (Get-GitCommit -RepoRoot $remoteRepoPath -Revision HEAD).Sha |
             Should -Be (Get-GitCommit -RepoRoot $localRepoPath -Revision HEAD).Sha
    }

    function ThenRemoteRevision
    {
        param(
            [Parameter(Position=0)]
            $Revision,

            [Switch]
            $Exists,

            [Switch]
            $DoesNotExist,

            $HasSha
        )

        $commitExists = Test-GitCommit -RepoRoot $remoteRepoPath -Revision $Revision
        if( $Exists )
        {
            $commitExists | Should -BeTrue
            if( $HasSha )
            {
                $commit = Get-GitCommit -RepoRoot $remoteRepoPath -Revision $Revision
                $commit.Sha | Should -Be $HasSha
            }
        }
        else
        {
            $commitExists | Should -Be $false
        }
    }

    function ThenPushResultIs
    {
        param(
            $PushStatus
        )

        $script:pushResult | Should -Be $PushStatus
    }

    function WhenSendingObject
    {
        [CmdletBinding()]
        param(
            $RefSpec,
            [Switch]
            $Tags
        )

        $Global:Error.Clear()
        $script:pushResult = $null

        $params = @{
                        RefSpec = $RefSpec
                    }
        if( $Tags )
        {
            $params = @{
                            Tags = $true
                        }
        }

        $script:pushResult = Send-GitObject -RepoRoot $localRepoPath @params
    }
}

Describe 'Send-GitObject' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testDirPath -ItemType Directory
    }

    It 'pushing changes to a remote repository' {
        GivenRemoteRepository 'RemoteRepo'
        GivenLocalRepositoryTracksRemote 'LocalRepo'
        GivenCommit
        WhenSendingObject 'refs/heads/master'
        ThenNoErrorsWereThrown
        ThenPushResultIs ([Git.Automation.PushResult]::Ok)
        ThenRemoteContainsLocalCommits
    }

    It 'there are no local changes to push to remote' {
        GivenRemoteRepository 'RemoteRepo'
        GivenLocalRepositoryTracksRemote 'LocalRepo'
        WhenSendingObject 'refs/heads/master'
        ThenNoErrorsWereThrown
        ThenPushResultIs ([Git.Automation.PushResult]::Ok)
    }

    It 'remote repository has changes not contained locally' {
        GivenRemoteRepository 'RemoteRepo'
        GivenLocalRepositoryTracksRemote 'LocalRepo'
        GivenRemoteContainsOtherChanges
        GivenCommit
        WhenSendingObject 'refs/heads/master' -ErrorAction SilentlyContinue
        ThenErrorWasThrown 'that you are trying to update on the remote contains commits that are not present locally.'
        ThenPushResultIs ([Git.Automation.PushResult]::Rejected)
    }

    It 'no upstream remote is defined' {
        GivenLocalRepositoryWithNoRemote 'LocalRepo'
        GivenCommit
        WhenSendingObject 'refs/heads/master' -ErrorAction SilentlyContinue
        ThenErrorWasThrown 'A\ remote\ named\ "origin"\ does\ not\ exist\.'
        ThenPushResultIs ([Git.Automation.PushResult]::Failed)
    }

    It 'refspec doesn''t exist' {
        GivenRemoteRepository 'RemoteRepo'
        GivenLocalRepositoryTracksRemote 'LocalRepo'
        WhenSendingObject 'refs/heads/dsfsdaf' -ErrorAction SilentlyContinue
        ThenErrorWasThrown 'does\ not\ match\ any\ existing\ object'
        ThenPushResultIs ([Git.Automation.PushResult]::Failed)
    }

    It 'pushing tags' {
        GivenRemoteRepository 'RemoteRepo'
        GivenLocalRepositoryTracksRemote 'LocalRepo'
        GivenTag 'tag1'
        GivenTag 'tag2'
        WhenSendingObject 'refs/tags/tag1'
        ThenRemoteRevision 'tag1' -Exists
        ThenRemoteRevision 'tag2' -DoesNotExist
    }

    It 'pushing all tags' {
        GivenRemoteRepository 'RemoteRepo'
        GivenLocalRepositoryTracksRemote 'LocalRepo'
        GivenTag 'tag1'
        GivenTag 'tag2'
        WhenSendingObject -Tags
        ThenRemoteRevision 'tag1' -Exists
        ThenRemoteRevision 'tag2' -Exists
    }

    It 'tags moved' {
        GivenRemoteRepository 'RemoteRepo'
        GivenLocalRepositoryTracksRemote 'LocalRepo'
        GivenTag 'tag1'
        GivenTag 'tag2'
        WhenSendingObject -Tags
        ThenRemoteRevision 'tag1' -Exists
        ThenRemoteRevision 'tag2' -Exists
        $commit = GivenCommit
        GivenTag 'tag1'
        GivenTag 'tag2'
        WhenSendingObject 'refs/heads/master'
        WhenSendingObject -Tags
        ThenRemoteRevision 'tag1' -Exists -HasSha $commit.Sha
        ThenRemoteRevision 'tag2' -Exists -HasSha $commit.Sha
    }
}