
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    function GivenRepositoryWithFile
    {
        param(
            [string[]]
            $Name
        )

        $script:repoRoot = New-GitTestRepo
        foreach($item in $Name)
        {
            New-Item -Path (Join-Path -Path $repoRoot -ChildPath $item) -Type 'File'
        }
        Add-GitItem -RepoRoot $repoRoot -Path $Name
        Save-GitCommit -RepoRoot $repoRoot -Message 'Commit to add test files'
    }

    function GivenIncorrectRepo
    {
        param(
            [string]
            $RepoName
        )

        $script:repoRoot = $RepoName
    }

    function GivenFileIsDeleted
    {
        param(
            [string[]]
            $Name
        )

        foreach($item in $Name)
        {
            Remove-Item -Path (Join-Path -Path $repoRoot -ChildPath $item)
        }
    }

    function GivenFileToStage
    {
        param(
            [string[]]
            $Name
        )

        $script:filesToStage = $Name
    }

    function WhenFileIsStaged
    {
        $Global:Error.Clear()
        Remove-GitItem -RepoRoot $repoRoot -Path $filesToStage -ErrorAction SilentlyContinue
    }

    function WhenFileIsStagedByPipeline
    {
        $Global:Error.Clear()
        ,$filesToStage | Remove-GitItem -RepoRoot $repoRoot -ErrorAction SilentlyContinue
    }

    function ThenFileShouldBeStaged
    {
        param(
            [string[]]
            $Path
        )

        foreach( $pathItem in $Path )
        {
            Get-GitRepositoryStatus -RepoRoot $repoRoot -Path $pathItem |
                Where-Object { $_.IsStaged } |
                Measure-Object |
                Select-Object -ExpandProperty 'Count' |
                Should -Be 1
        }
    }

    function ThenFileShouldNotBeStaged
    {
        param(
            [string[]]
            $Path
        )

        foreach( $pathItem in $Path )
        {
            Get-GitRepositoryStatus -RepoRoot $repoRoot -Path $pathItem |
                Where-Object { $_.IsStaged } |
                Measure-Object |
                Select-Object -ExpandProperty 'Count' |
                Should -Be 0
        }
    }

    function ThenFileShouldBeDeleted
    {
        param(
            [string[]]
            $Path
        )

        foreach( $pathItem in $Path )
        {
            Test-Path -Path (join-Path -Path $repoRoot -ChildPath $pathItem) | Should -be $false
        }
    }

    function ThenNoErrorShouldBeThrown
    {
        $Global:Error | Should -BeNullOrEmpty
    }
    function ThenErrorShouldBeThrown
    {
        param(
            [String]
            $ExpectedError
        )

        $Global:Error | Where-Object { $_ -match $ExpectedError } | Should -Not -BeNullOrEmpty
    }
}

Describe 'Remove-GitItem' {
    It 'file is moved from git repository correctly' {
        GivenRepositoryWithFile -Name 'foo.bar'
        GivenFileToStage -Name 'foo.bar'
        WhenFileIsStaged
        ThenFileShouldBeStaged -Path 'foo.bar'
        ThenFileShouldBeDeleted -Path 'foo.bar'
        ThenNoErrorShouldBeThrown
    }

    It 'multiple Files are moved from git repository correctly' {
        GivenRepositoryWithFile -Name 'foo.bar', 'bar.fooo'
        GivenFileToStage  -Name 'foo.bar', 'bar.fooo'
        WhenFileIsStaged
        ThenFileShouldBeStaged -Path 'foo.bar', 'bar.fooo'
        ThenFileShouldBeDeleted -Path 'foo.bar', 'bar.fooo'
        ThenNoErrorShouldBeThrown
    }

    It 'multiple Files are moved from git repository correctly via the pipeline' {
        GivenRepositoryWithFile -Name 'foo.bar', 'bar.fooo'
        GivenFileToStage  -Name 'foo.bar', 'bar.fooo'
        WhenFileIsStagedByPipeline
        ThenFileShouldBeStaged -Path 'foo.bar', 'bar.fooo'
        ThenFileShouldBeDeleted -Path 'foo.bar', 'bar.fooo'
        ThenNoErrorShouldBeThrown
    }

    It 'file is moved from git repository correctly via the pipeline' {
        GivenRepositoryWithFile -Name 'foo.bar'
        GivenFileToStage -Name 'foo.bar'
        WhenFileIsStagedByPipeline
        ThenFileShouldBeStaged -Path 'foo.bar'
        ThenFileShouldBeDeleted -Path 'foo.bar'
        ThenNoErrorShouldBeThrown
    }

    It 'file is already removed from git repository correctly' {
        GivenRepositoryWithFile -Name 'foo.bar'
        GivenFileIsDeleted -Name 'foo.bar'
        GivenFileToStage  -Name 'foo.bar'
        WhenFileIsStaged
        ThenFileShouldBeStaged -Path 'foo.bar'
        ThenFileShouldBeDeleted -Path 'foo.bar'
        ThenNoErrorShouldBeThrown
    }

    It 'file doesnt exist in the repository' {
        GivenRepositoryWithFile -Name 'a.file'
        GivenFileToStage  -Name 'different.file'
        WhenFileIsStaged
        ThenFileShouldNotBeStaged -Path 'different.file'
        ThenNoErrorShouldBeThrown
    }

    It 'invalid repository is passed' {
        GivenIncorrectRepo -RepoName 'foobar'
        WhenFileIsStaged
        ThenErrorShouldBeThrown -ExpectedError 'Can''t find a repository in ''foobar'''
    }
}