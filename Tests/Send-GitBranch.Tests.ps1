
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
    [Git.Automation.SendBranchResult]$script:result = $null

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

    function ThenHeadsDifferent
    {
        param(
            $BranchName = 'master'
        )

        $serverRepo = Get-GitRepository $script:serverBareDirectory
        $clientRepo = Get-GitRepository $script:clientDirectory
        try
        {
            $serverBranchCommit = $serverRepo.Branches[$BranchName]
            $clientBranchCommit = $clientRepo.Branches[$BranchName]
            if ($serverBranchCommit)
            {
                $serverBranchCommit.Tip.Sha | Should -Not -Be $clientBranchCommit.Tip.Sha
            }
            else
            {
                $null -eq $serverBranchCommit -and $null -eq $clientBranchCommit | Should -BeFalse
            }
        }
        finally
        {
            $clientRepo.Dispose()
            $serverRepo.Dispose()
        }
    }

    function ThenHeadsSame
    {
        param(
            $BranchName = 'master'
        )

        $serverRepo = Get-GitRepository $script:serverBareDirectory
        $clientRepo = Get-GitRepository $script:clientDirectory
        try
        {
            $serverRepo.Branches[$BranchName].Tip.Sha | Should -Be $clientRepo.Branches[$BranchName].Tip.Sha
        }
        finally
        {
            $clientRepo.Dispose()
            $serverRepo.Dispose()
        }
    }

    function ThenMergeStatusIs
    {
        param(
            [LibGit2Sharp.MergeStatus]
            $ExpectedStatus
        )

        $script:result.LastMergeResult.Status | Should -Be $ExpectedStatus
    }

    function ThenPushStatus
    {
        param(
            [Parameter(Mandatory=$true,ParameterSetName='Is')]
            [Git.Automation.PushResult]
            $Is,

            [Parameter(Mandatory=$true,ParameterSetName='IsNull')]
            [Switch]
            $IsNull
        )

        if( $PSCmdlet.ParameterSetName -eq 'Is' )
        {
            $script:result.LastPushResult | Should -Be $Is
        }
        else
        {
            $script:result.LastPushResult | Should -BeNullOrEmpty
        }
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

        $script:result = Send-GitBranch -RepoRoot $RepoRoot @mergeStrategyArg
    }
}

Describe 'Send-GitBranch' {
    BeforeEach {
        $Global:Error.Clear()

        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
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
        ThenMergeStatusIs 'UpToDate'
        ThenPushStatus -Is Ok
        ThenHeadIsLastCommit
        ThenHeadsSame
    }

    It 'no new commits local and no new commits on server' {
        WhenUpdated -RepoRoot $script:clientDirectory
        ThenMergeStatusIs 'UpToDate'
        ThenPushStatus -Is Ok
        ThenHeadIsLastCommit
        ThenHeadsSame
    }

    It 'no new commits local and new commits on server and fast forwarding' {
        GivenNewCommitIn $script:serverWorkingDirectory -AndPushed
        WhenUpdated -RepoRoot $script:clientDirectory
        ThenMergeStatusIs 'FastForward'
        ThenPushStatus -Is Ok
        ThenHeadIsLastCommit
        ThenHeadsSame
    }

    It 'no new commits local and new commits on server and merging' {
        GivenNewCommitIn $script:serverWorkingDirectory -AndPushed
        WhenUpdated -RepoRoot $script:clientDirectory -AndMergeStrategyIs 'Merge'
        ThenMergeStatusIs 'NonFastForward'
        ThenPushStatus -Is Ok
        ThenHeadIsNewCommit
        ThenHeadsSame
    }

    It 'new commits local and new commits on server' {
        GivenNewCommitIn $script:serverWorkingDirectory -AndPushed
        GivenNewCommitIn $script:clientDirectory
        WhenUpdated -RepoRoot $script:clientDirectory
        ThenMergeStatusIs 'NonFastForward'
        ThenPushStatus -Is Ok
        ThenHeadIsNewCommit
        ThenHeadsSame
    }

    It 'new commits local and new commits on server and merge must be fast-forwarded' {
        GivenNewCommitIn $script:serverWorkingDirectory -AndPushed
        GivenNewCommitIn $script:clientDirectory
        WhenUpdated -RepoRoot $script:clientDirectory -AndMergeStrategyIs 'FastForward' -ErrorAction SilentlyContinue
        ThenPushStatus -IsNull
        ThenUpdateFailed
        ThenErrorIs 'Cannot\ perform\ fast-forward\ merge'
        ThenHeadIsLastCommit
        ThenHeadsDifferent
    }

    It 'no local branch' {
        GivenNewCommitIn $script:clientDirectory
        GivenCheckedOut $script:lastCommit.Sha
        WhenUpdated -RepoRoot $script:clientDirectory -ErrorAction SilentlyContinue
        ThenPushStatus -IsNull
        ThenUpdateFailed
        ThenErrorIs 'isn''t\ on\ a\ branch'
        ThenHeadIsLastCommit
        ThenHeadsDifferent
    }

    It 'no tracking branch and there is a remote equivalent' {
        GivenNewCommitIn $script:clientDirectory
        GivenNewCommitIn $script:serverWorkingDirectory -AndPushed
        GivenNoUpstreamBranchFor 'master'
        WhenUpdated -RepoRoot $script:clientDirectory
        ThenMergeStatusIs 'NonFastForward'
        ThenPushStatus -Is Ok
        ThenHeadIsNewCommit
        ThenHeadsSame
    }

    It 'no tracking branch and there is no remote equivalent' {
        GivenBranch 'develop'
        GivenNewCommitIn $script:clientDirectory
        WhenUpdated -RepoRoot $script:clientDirectory -ErrorAction SilentlyContinue
        ThenPushStatus -IsNull
        ThenUpdateFailed
        ThenErrorIs 'unable\ to\ find\ a\ remote\ branch\ named\ "develop"'
        ThenHeadIsLastCommit 'develop'
        ThenHeadsDifferent 'develop'
    }

    It 'the given repo doesn''t exist' {
        Send-GitBranch -RepoRoot 'C:\I\do\not\exist' -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'does not exist'
    }

    It 'there are conflicts between local and remote' {
        GivenConflicts
        WhenUpdated -RepoRoot $script:clientDirectory -ErrorAction SilentlyContinue
        ThenPushStatus -IsNull
        ThenMergeStatusIs 'Conflicts'
        ThenHeadIsLastCommit
        ThenHeadsDifferent
    }
}
