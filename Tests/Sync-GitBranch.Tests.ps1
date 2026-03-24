
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:testDirPath = $null
    $script:testNum = 0
    $script:serverWorkingDirectory = $null
    $script:serverBareDirectory = $null
    $script:clientDirectory = $null
    [Git.Automation.CommitInfo]$script:lastCommit = $null

    function GivenBranch
    {
        param(
            $BranchName
        )

        New-GitBranch -RepoRoot $script:clientDirectory -Name $BranchName
    }

    function GivenCheckedOut
    {
        param(
            $Revision
        )

        Update-GitRepository -RepoRoot $script:clientDirectory -Revision $Revision
    }

    function GivenConflicts
    {
        foreach( $dir in @( $script:serverWorkingDirectory, $script:clientDirectory ) )
        {
            $filePath = Join-Path -Path $dir -ChildPath 'first'
            [Guid]::NewGuid() | Set-Content -Path $filePath
            Add-GitItem -Path $filePath -RepoRoot $dir
            $script:lastCommit = Save-GitCommit -RepoRoot $dir -Message 'conflict first'
        }

        Send-GitCommit -RepoRoot $script:serverWorkingDirectory
    }

    function GivenNewCommitIn
    {
        param(
            $Directory,
            [Switch]
            $AndPushed
        )

        Push-Location -Path $Directory
        try
        {
            $filePath = [IO.Path]::GetRandomFileName()
            New-Item -Path $filePath -ItemType 'File'
            Add-GitItem -Path $filePath
            $script:lastCommit = Save-GitCommit -Message $filePath

            if( $AndPushed )
            {
                Send-GitCommit
            }
        }
        finally
        {
            Pop-Location
        }
    }

    function GivenNoUpstreamBranchFor
    {
        param(
            $BranchName
        )

        $repo = Get-GitRepository -RepoRoot $script:clientDirectory
        try
        {
            $branch = $repo.Branches | Where-Object { $_.FriendlyName -eq $BranchName }
            $repo.Branches.Update($branch, {
                param(
                    [LibGit2Sharp.BranchUpdater]
                    $Updater
                )

                $Updater.TrackedBranch = ''
                $Updater.Remote = ''
                $Updater.UpstreamBranch = ''
            })
        }
        finally
        {
            $repo.Dispose()
        }
    }

    function ThenErrorIs
    {
        param(
            $Pattern
        )

        $Global:Error | Should -Match $Pattern
    }

    function ThenHeadIsLastCommit
    {
        param(
            $BranchName = 'master'
        )

        $repo = Get-GitRepository -RepoRoot $script:clientDirectory
        try
        {
            $repo.Branches[$BranchName].Tip.Sha | Should -Be $script:lastCommit.Sha
        }
        finally
        {
            $repo.Dispose()
        }
    }

    function ThenHeadIsNewCommit
    {
        $repo = Get-GitRepository -RepoRoot $script:clientDirectory
        try
        {
            $head = $repo.Branches['master'].Tip
            $head.Sha | Should -Not -Be $script:lastCommit.Sha
            $head.Parents | Where-Object { $_.Sha -eq $script:lastCommit.Sha } | Should -Not -BeNullOrEmpty
        }
        finally
        {
            $repo.Dispose()
        }
    }

    function ThenStatusIs
    {
        param(
            [LibGit2Sharp.MergeStatus]
            $ExpectedStatus
        )

        $result.Status | Should -Be $ExpectedStatus
    }

    function ThenUpdateFailed
    {
        $script:result | Should -BeNullOrEmpty
        $Global:Error | Should -Not -BeNullOrEmpty
    }

    function WhenUpdated
    {
        [CmdletBinding()]
        param(
            $RepoRoot,
            $AndMergeStrategyIs
        )

        $mergeStrategyArg = @{}
        if( $AndMergeStrategyIs )
        {
            $mergeStrategyArg['MergeStrategy'] = $AndMergeStrategyIs
        }

        $script:result = Sync-GitBranch -RepoRoot $RepoRoot @mergeStrategyArg
    }
}

Describe 'Sync-GitBranch' {
    BeforeEach {
        $Global:Error.Clear()

        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testDirPath -ItemType Directory

        $script:serverBareDirectory = Join-Path -Path $script:testDirPath -ChildPath 'Server'
        New-GitRepository -Path $script:serverBareDirectory -Bare

        $script:serverWorkingDirectory = Join-Path -Path $script:testDirPath -ChildPath 'Server.Working'
        Copy-GitRepository -Source $script:serverBareDirectory -DestinationPath $script:serverWorkingDirectory

        Push-Location -Path $script:serverWorkingDirectory
        try
        {
            '' | Set-Content -Path 'master'
            Add-GitItem 'master'
            $script:lastCommit = Save-GitCommit -Message 'first'
            Send-GitCommit
        }
        finally
        {
            Pop-Location
        }

        $script:clientDirectory = Join-Path -Path $script:testDirPath -ChildPath 'Client'
        Copy-GitRepository -Source $script:serverBareDirectory -DestinationPath $script:clientDirectory
    }

    It 'no new commits on the server' {
        GivenNewCommitIn $script:clientDirectory
        WhenUpdated -RepoRoot $script:clientDirectory
        ThenStatusIs 'UpToDate'
        ThenHeadIsLastCommit
    }

    It 'no new commits local and no new commits on server' {
        WhenUpdated -RepoRoot $script:clientDirectory
        ThenStatusIs 'UpToDate'
        ThenHeadIsLastCommit
    }

    It 'no new commits local and new commits on server' {
        GivenNewCommitIn $script:serverWorkingDirectory -AndPushed
        WhenUpdated -RepoRoot $script:clientDirectory
        ThenStatusIs 'FastForward'
        ThenHeadIsLastCommit
    }

    It 'no new commits local and new commits on server' {
        GivenNewCommitIn $script:serverWorkingDirectory -AndPushed
        WhenUpdated -RepoRoot $script:clientDirectory -AndMergeStrategyIs 'Merge'
        ThenStatusIs 'NonFastForward'
        ThenHeadIsNewCommit
    }

    It 'new commits local and new commits on server' {
        GivenNewCommitIn $script:serverWorkingDirectory -AndPushed
        GivenNewCommitIn $script:clientDirectory
        WhenUpdated -RepoRoot $script:clientDirectory
        ThenStatusIs 'NonFastForward'
        ThenHeadIsNewCommit
    }

    It 'new commits local and new commits on server and merge must be fast-forwarded' {
        GivenNewCommitIn $script:serverWorkingDirectory -AndPushed
        GivenNewCommitIn $script:clientDirectory
        WhenUpdated -RepoRoot $script:clientDirectory -AndMergeStrategyIs 'FastForward' -ErrorAction SilentlyContinue
        ThenUpdateFailed
        ThenErrorIs 'Cannot\ perform\ fast-forward\ merge'
        ThenHeadIsLastCommit
    }

    It 'no local branch' {
        GivenNewCommitIn $script:clientDirectory
        GivenCheckedOut $script:lastCommit.Sha
        WhenUpdated -RepoRoot $script:clientDirectory -ErrorAction SilentlyContinue
        ThenUpdateFailed
        ThenErrorIs 'isn''t\ on\ a\ branch'
        ThenHeadIsLastCommit
    }

    It 'no tracking branch and there is a remote equivalent' {
        GivenNewCommitIn $script:clientDirectory
        GivenNewCommitIn $script:serverWorkingDirectory -AndPushed
        GivenNoUpstreamBranchFor 'master'
        WhenUpdated -RepoRoot $script:clientDirectory
        ThenStatusIs 'NonFastForward'
        ThenHeadIsNewCommit
    }

    It 'no tracking branch and there is no remote equivalent' {
        GivenBranch 'develop'
        GivenNewCommitIn $script:clientDirectory
        WhenUpdated -RepoRoot $script:clientDirectory -ErrorAction SilentlyContinue
        ThenUpdateFailed
        ThenErrorIs 'unable\ to\ find\ a\ remote\ branch\ named\ "develop"'
        ThenHeadIsLastCommit 'develop'
    }

    It 'the given repo doesn''t exist' {
        Sync-GitBranch -RepoRoot 'C:\I\do\not\exist' -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'does not exist'
    }

    It 'there are conflicts between local and remote' {
        GivenConflicts
        WhenUpdated -RepoRoot $script:clientDirectory
        ThenStatusIs 'Conflicts'
        ThenHeadIsLastCommit
    }
}