
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    [LibGit2Sharp.TreeChanges]$script:diffOutput = $null
    $script:repoRoot = $null
    $script:repoNum = 0

    function GivenACommit
    {
        param(
            $ThatAdds,
            $ThatModifies
        )

        if ($ThatAdds)
        {
            Add-GitTestFile -RepoRoot $script:repoRoot -Path $ThatAdds
            Add-GitItem -RepoRoot $script:repoRoot -Path $ThatAdds
        }

        if ($ThatModifies)
        {
            [Guid]::NewGuid() | Select-Object -ExpandProperty Guid | Set-Content -Path (Join-Path -Path $script:repoRoot -ChildPath $ThatModifies) -Force
            Add-GitItem -RepoRoot $script:repoRoot -Path $ThatModifies
        }

        Save-GitCommit -RepoRoot $script:repoRoot -Message 'Compare-GitTree tests commit'
    }

    function GivenARepository
    {
        $script:repoRoot = Join-Path -Path $TestDrive -ChildPath "$($script:repoNum++)\repo"
        New-GitRepository -Path $script:repoRoot | Out-Null

        Add-GitTestFile -RepoRoot $script:repoRoot -Path 'InitialCommit.txt'
        Add-GitItem -RepoRoot $script:repoRoot -Path 'InitialCommit.txt'
        Save-GitCommit -RepoRoot $script:repoRoot -Message 'Initial Commit'
    }

    function GivenTag
    {
        param(
            $Tag
        )

        New-GitTag -RepoRoot $script:repoRoot -Name $Tag
    }

    function WhenGettingDiff
    {
        [CmdletBinding(DefaultParameterSetName='Default')]
        param(
            [Parameter(ParameterSetName='RepositoryRoot')]
            [switch]
            $GivenRepositoryRoot,

            [Parameter(ParameterSetName='RepositoryObject')]
            [switch]
            $GivenRepositoryObject,

            [Parameter(Mandatory=$true)]
            [string]
            $ReferenceCommit,

            [string]
            $DifferenceCommit
        )

        $DifferenceCommitParam = @{}
        if ($DifferenceCommit)
        {
            $DifferenceCommitParam['DifferenceCommit'] = $DifferenceCommit
        }

        if ($GivenRepositoryRoot)
        {
            $script:diffOutput = Compare-GitTree -RepositoryRoot $script:repoRoot -ReferenceCommit $ReferenceCommit @DifferenceCommitParam
        }
        elseif ($GivenRepositoryObject)
        {
            Mock -CommandName 'Invoke-Command' -ModuleName 'GitAutomation' -ParameterFilter { $ScriptBlock.ToString() -match 'Dispose' }
            $repoObject = Get-GitRepository -RepoRoot $script:repoRoot
            try
            {
                $script:diffOutput = Compare-GitTree -RepositoryObject $repoObject -ReferenceCommit $ReferenceCommit @DifferenceCommitParam
            }
            finally
            {
                $repoObject.Dispose()
            }
        }
        else
        {
            Push-Location -Path $script:repoRoot
            try
            {
                $result = Compare-GitTree -ReferenceCommit $ReferenceCommit @DifferenceCommitParam
                if( $result )
                {
                    $script:diffOutput = $result
                }
            }
            finally
            {
                Pop-Location
            }
        }
    }

    function ThenDidNotDisposeRepoObject
    {
        Should -Invoke 'Invoke-Command' `
               -ModuleName 'GitAutomation' `
               -ParameterFilter { $ScriptBlock.ToString() -match 'Dispose' } -Times 0
    }

    function ThenDiffCount
    {
        param(
            [int]
            $Added,
            [int]
            $Deleted,
            [int]
            $Modified,
            [int]
            $Renamed
        )

        ($script:diffOutput.Added | Measure-Object).Count | Should -Be $Added
        ($script:diffOutput.Deleted | Measure-Object).Count  | Should -Be $Deleted
        ($script:diffOutput.Modified | Measure-Object).Count | Should -Be $Modified
        ($script:diffOutput.Renamed | Measure-Object).Count  | Should -Be $Renamed
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
            $script:diffOutput | Should -BeNullOrEmpty
        }
        else
        {
            , $script:diffOutput | Should -BeOfType $Type
        }
    }
}

Describe 'Compare-GitTree' {
    BeforeEach {
        $Global:Error.Clear()
        $script:diffOutput = $null
        $script:repoRoot = $null
    }

    It 'a commit does not exist' {
        GivenARepository
        WhenGettingDiff -ReferenceCommit 'nonexistentcommit' -ErrorAction SilentlyContinue
        ThenReturned -Nothing
        ThenErrorMessage 'Commit ''nonexistentcommit'' not found in repository'
    }

    It 'getting diff between HEAD and its parent commit in the current directory repository' {
        GivenARepository
        GivenACommit -ThatAdds 'file1.txt'
        WhenGettingDiff -ReferenceCommit 'HEAD^'
        ThenReturned -Type [LibGit2Sharp.TreeChanges]
        ThenDiffCount -Added 1
        ThenNoErrorMessages
    }

    It 'getting diff between HEAD and its parent commit for the given repository path' {
        GivenARepository
        GivenACommit -ThatAdds 'file1.txt'
        WhenGettingDiff -GivenRepositoryRoot -ReferenceCommit 'HEAD^'
        ThenReturned -Type [LibGit2Sharp.TreeChanges]
        ThenDiffCount -Added 1
        ThenNoErrorMessages
    }

    It 'getting diff between HEAD and its parent commit for the given repository Object' {
        GivenARepository
        GivenACommit -ThatAdds 'file1.txt'
        WhenGettingDiff -GivenRepositoryObject -ReferenceCommit 'HEAD^'
        ThenReturned -Type [LibGit2Sharp.TreeChanges]
        ThenDiffCount -Added 1
        ThenDidNotDisposeRepoObject
        ThenNoErrorMessages
    }

    It 'getting diff between two specific commits' {
        GivenARepository
        GivenACommit -ThatAdds 'file1.txt', 'file2.txt'
        GivenTag '1.0'
        GivenACommit -ThatModifies 'file2.txt'
        GivenACommit -ThatAdds 'file3.txt'
        GivenTag '2.0'
        GivenACommit -ThatAdds 'fileafter2.0.txt'
        WhenGettingDiff -ReferenceCommit '1.0' -DifferenceCommit '2.0'
        ThenReturned -Type [LibGit2Sharp.TreeChanges]
        ThenDiffCount -Added 1 -Modified 1
        ThenNoErrorMessages
    }
}