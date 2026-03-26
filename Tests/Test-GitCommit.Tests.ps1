
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:repoRoot = $null
    $script:testNum = 0
    $script:result = $null

    function GivenBranch
    {
        param(
            $Name
        )

        New-GitBranch -RepoRoot $script:repoRoot -Name $Name
    }

    function GivenRepository
    {
        New-GitRepository -Path $script:repoRoot
        Add-GitTestFile -RepoRoot $script:repoRoot -Path 'first'
        Add-GitItem -Path 'first' -RepoRoot $script:repoRoot
        Save-GitCommit -Message 'first' -RepoRoot $script:repoRoot
    }

    function GivenTag
    {
        param(
            $Name
        )

        New-GitTag -RepoRoot $script:repoRoot -Name $Name
    }

    function ThenNoErrors
    {
        $Global:Error | Should -BeNullOrEmpty
    }

    function ThenReturnedFalse
    {
        $script:result | Should -BeFalse
    }

    function ThenReturnedTrue
    {
        $script:result | Should -BeTrue
    }

    function WhenTestingRevision
    {
        param(
            $Revision,
            [Switch]
            $NoRepoRootParameter
        )

        $script:repoRootParam = @{ 'RepoRoot' = $script:repoRoot }
        if( $NoRepoRootParameter )
        {
            $script:repoRootParam = @{ }
        }

        $Global:Error.Clear()
        $script:result = Test-GitCommit -Revision $Revision @repoRootParam
    }
}

Describe 'Test-GitCommit' {
    BeforeEach {
        $script:repoRoot = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        $script:result = $null
    }

    It 'revision doesn''t exist' {
        GivenRepository
        WhenTestingRevision 'fubarsnafu'
        ThenReturnedFalse
        ThenNoErrors
    }

    It 'testing with SHA' {
        GivenRepository
        WhenTestingRevision (Get-GitCommit -Revision 'HEAD' -RepoRoot $script:repoRoot).Sha
        ThenReturnedTrue
        ThenNoErrors
    }

    It 'testing with truncated SHA' {
        GivenRepository
        WhenTestingRevision (Get-GitCommit -Revision 'HEAD' -RepoRoot $script:repoRoot).Sha.Substring(0,7)
        ThenReturnedTrue
        ThenNoErrors
    }

    It 'using tag' {
        GivenRepository
        GivenTag 'fubarsnafu'
        WhenTestingRevision 'fubarsnafu'
        ThenReturnedTrue
        ThenNoErrors
    }

    It 'using branch' {
        GivenRepository
        GivenBranch 'some-branch'
        WhenTestingRevision 'some-branch'
        ThenReturnedTrue
        ThenNoErrors
    }

    It 'working in current directory' {
        GivenRepository
        GivenBranch 'some-branch'
        Push-Location -Path $script:repoRoot
        try
        {
            WhenTestingRevision 'some-branch' -NoRepoRootParameter
            ThenReturnedTrue
            ThenNoErrors
        }
        finally
        {
            Pop-Location
        }
    }
}