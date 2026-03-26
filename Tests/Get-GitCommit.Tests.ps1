
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:commitOutput = $null
    $script:repoRoot = $null
    $script:testNum = 0

    function GivenRepository
    {
        New-GitRepository -Path $script:repoRoot | Out-Null
    }

    function GivenBranch
    {
        param(
            $Name
        )

        New-GitBranch -RepoRoot $script:repoRoot -Name $Name
    }

    function GivenCommit
    {
        param(
            [int]
            $NumberOfCommits = 1
        )

        1..$NumberOfCommits | ForEach-Object {
            $filePath = Join-Path -Path $script:repoRoot -ChildPath ([System.IO.Path]::GetRandomFileName())
            [Guid]::NewGuid() | Set-Content -Path $filePath -Force
            Add-GitItem -Path $filePath -RepoRoot $script:repoRoot | Out-Null
            Save-GitCommit -Message 'Get-GitCommit Tests' -RepoRoot $script:repoRoot | Out-Null
        }
    }

    function GivenHeadIs
    {
        param(
            $Revision
        )

        Update-GitRepository -RepoRoot $script:repoRoot -Revision $Revision
    }

    function AddMerge
    {
        try
        {
            # Temporary until we get merge functionality in this module
            $repo = Find-GitRepository -Path $script:repoRoot

            $testBranch = 'GitCommitTestBranch'
            New-GitBranch -RepoRoot $script:repoRoot -Name $testBranch

            GivenCommit -NumberOfCommits 1
            [LibGit2Sharp.Commands]::Checkout($repo, 'master', (New-Object LibGit2Sharp.CheckoutOptions))

            $mergeOptions = New-Object LibGit2Sharp.MergeOptions
            $mergeOptions.FastForwardStrategy = 'NoFastForward'
            $mergeSignature = New-Object LibGit2Sharp.Signature -ArgumentList 'test','email@example.com',([System.DateTimeOffset]::Now)

            $repo.Merge($testBranch, $mergeSignature, $mergeOptions)
        }
        finally
        {
            $repo.Dispose()
        }
    }

    function AddTag
    {
        param(
            $Tag
        )

        New-GitTag -RepoRoot $script:repoRoot -Name $Tag
    }

    function WhenGettingCommit
    {
        [CmdletBinding(DefaultParameterSetName='Default')]
        param(
            [Parameter(ParameterSetName='All')]
            [switch]
            $All,

            [Parameter(ParameterSetName='Lookup')]
            [string]
            $Revision,

            [Parameter(ParameterSetName='CommitFilter')]
            [string]
            $Since = 'HEAD',

            [Parameter(ParameterSetName='CommitFilter')]
            [string]
            $Until,

            [Parameter(ParameterSetName='CommitFilter')]
            [switch]
            $NoMerges
        )

        if ($PSCmdlet.ParameterSetName -eq 'All')
        {
            $script:commitOutput = Get-GitCommit -RepoRoot $script:repoRoot -All
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'Lookup')
        {
            $script:commitOutput = Get-GitCommit -RepoRoot $script:repoRoot -Revision $Revision
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'CommitFilter')
        {
            $script:commitOutput =
                Get-GitCommit -RepoRoot $script:repoRoot -Since $Since -Until $Until -NoMerges:$NoMerges
        }
        else
        {
            Push-Location $script:repoRoot
            try
            {
                $script:commitOutput = Get-GitCommit
            }
            finally
            {
                Pop-Location
            }
        }
    }

    function ThenCommitIsHeadCommit
    {
        $script:commitOutput.Sha |
            Should -Be (Get-Content -Path (Join-Path -Path $script:repoRoot -ChildPath '.git\refs\heads\master'))
    }

    function ThenNumberCommitsReturnedIs
    {
        param(
            [int]
            $NumberOfCommits
            )

            $commitsReturned = $script:commitOutput | Measure-Object | Select-Object -ExpandProperty 'Count'
            $commitsReturned | Should -Be $NumberOfCommits
    }

    function ThenReturned
    {
        param(
            [Parameter(Mandatory=$true,ParameterSetName='Type')]
            $Type,
            [Parameter(Mandatory=$true,ParameterSetName='Nothing')]
            [switch]
            $Nothing
            )

        if ($Nothing)
        {
            $script:commitOutput | Should -BeNullOrEmpty
        }
        else
        {
            $script:commitOutput | Should -BeOfType $Type
        }
    }

    function ThenErrorMessage
    {
        param(
            $Message
        )

        $Global:Error[0] | Should -Match $Message
    }

    function ThenNoErrorMessages
    {
        $Global:Error | Should -BeNullOrEmpty
    }
}

Describe 'Get-GitCommit' {
    BeforeEach {
        $Global:Error.Clear()
        $script:commitOutput = $null
        $script:repoRoot = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
    }

    It 'no parameters specified' {
        GivenRepository
        GivenCommit -NumberOfCommits 2
        WhenGettingCommit
        ThenReturned -Type [Git.Automation.CommitInfo]
        ThenNumberCommitsReturnedIs 2
        ThenNoErrorMessages
    }

    It 'getting all commits' {
        GivenRepository
        GivenCommit -NumberOfCommits 5
        GivenHeadIs 'master'
        GivenBranch 'somebranch'
        GivenCommit -NumberOfCommits 5
        GivenHeadIs 'master'
        GivenBranch 'someotherbranch'
        GivenCommit -NumberOfCommits 5
        WhenGettingCommit -All
        ThenReturned -Type [Git.Automation.CommitInfo]
        ThenNumberCommitsReturnedIs 15
        ThenNoErrorMessages
    }

    It 'getting specifically the current HEAD commit' {
        GivenRepository
        GivenCommit -NumberOfCommits 3
        WhenGettingCommit -Revision 'HEAD'
        ThenReturned -Type [Git.Automation.CommitInfo]
        ThenNumberCommitsReturnedIs 1
        ThenCommitIsHeadCommit
        ThenNoErrorMessages
    }

    It 'getting a commit that does not exist' {
        GivenRepository
        GivenCommit -NumberOfCommits 1
        WhenGettingCommit -Revision 'nonexistentcommit' -ErrorAction SilentlyContinue
        ThenReturned -Nothing
        ThenErrorMessage 'Commit ''nonexistentcommit'' not found in repository'
    }

    It 'getting commit list with an invalid commit' {
        GivenRepository
        GivenCommit -NumberOfCommits 1
        WhenGettingCommit -Since 'HEAD' -Until 'nonexistentcommit' -ErrorAction SilentlyContinue
        ThenReturned -Nothing
        ThenErrorMessage 'Commit ''nonexistentcommit'' not found in repository'
    }

    It 'Since and Until are the same commit' {
        GivenRepository
        GivenCommit -NumberOfCommits 1
        AddTag '1.0'
        WhenGettingCommit -Since 'HEAD' -Until '1.0' -ErrorAction SilentlyContinue
        ThenReturned -Nothing
        ThenErrorMessage 'Commit reference ''HEAD'' and ''1.0'' refer to the same commit'
    }

    It 'getting all commits until a specific commit' {
        GivenRepository
        GivenCommit -NumberOfCommits 1
        AddTag '1.0'
        GivenCommit -NumberOfCommits 3
        WhenGettingCommit -Until '1.0'
        ThenReturned -Type [Git.Automation.CommitInfo]
        ThenNumberCommitsReturnedIs 3
        ThenNoErrorMessages
    }

    It 'getting list of commits between two specific commits' {
        GivenRepository
        GivenCommit -NumberOfCommits 1
        AddTag '1.0'
        GivenCommit -NumberOfCommits 2
        AddMerge # Adds 2 commits (regular + merge commit)
        AddTag '2.0'
        GivenCommit -NumberOfCommits 1
        WhenGettingCommit -Since '2.0' -Until '1.0'
        ThenReturned -Type [Git.Automation.CommitInfo]
        ThenNumberCommitsReturnedIs 4
        ThenNoErrorMessages
    }

    It 'getting list of commits with excluding merge commits' {
        GivenRepository
        GivenCommit -NumberOfCommits 1
        AddTag '1.0'
        GivenCommit -NumberOfCommits 2
        AddMerge # Adds 2 commits (regular + merge commit)
        AddTag '2.0'
        GivenCommit -NumberOfCommits 1
        WhenGettingCommit -Since '2.0' -Until '1.0' -NoMerges
        ThenReturned -Type [Git.Automation.CommitInfo]
        ThenNumberCommitsReturnedIs 3
        ThenNoErrorMessages
    }
}
