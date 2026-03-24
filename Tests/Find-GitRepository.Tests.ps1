
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    function Assert-ThisRepositoryFound
    {
        param(
            [LibGit2Sharp.Repository]
            $Repository
        )

        $Repository | Should -Not -BeNullOrEmpty
        $Repository.Info.WorkingDirectory | Should -Be (Join-Path -Path $PSScriptRoot -ChildPath '..\' -Resolve)
    }

    function Assert-NoRepositoryReturned
    {
        param(
            [LibGit2Sharp.Repository]
            $Repository
        )

        $Repository | Should -BeNullOrEmpty
    }
}

Describe 'Find-GitRepository' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'the current directory is under a repository root' {
        Push-Location -Path $PSScriptRoot
        try
        {
            $repo = Find-GitRepository
            Assert-ThisRepositoryFound -Repository $repo
        }
        finally
        {
            Pop-Location
        }
    }

    It 'the current directory has no repository' {
        Push-Location -Path $env:TEMP
        try
        {
            $repo = Find-GitRepository
            Assert-NoRepositoryReturned -Repository $repo
            $Global:Error.Count | Should -Be 0
        }
        finally
        {
            Pop-Location
        }
    }

    It 'given a relative path' {
        Push-Location -Path $PSScriptRoot
        try
        {
            $repo = Find-GitRepository -Path '..\GitAutomation\bin'
            Assert-ThisRepositoryFound -Repository $repo
        }
        finally
        {
            Pop-Location
        }
    }

    It 'a path doesn''t exist' {
        $repo = Find-GitRepository -Path 'C:\I\do\not\exist' -ErrorAction SilentlyContinue
        Assert-NoRepositoryReturned $repo
        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'does not exist'
    }

    It 'passed full path to repository root' {
        $repo = Find-GitRepository -Path (Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve)
        Assert-ThisRepositoryFound -Repository $repo
    }


    It 'current directory is a repository root' {
        Push-Location -Path (Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve)
        try
        {
            $repo = Find-GitRepository
            Assert-ThisRepositoryFound -Repository $repo
        }
        finally
        {
            Pop-Location
        }
    }

    It '-Verify switch is used and a repository isn''t found' {
        $repo = Find-GitRepository -Path $env:TEMP -Verify -ErrorAction SilentlyContinue
        Assert-NoRepositoryReturned -Repository $repo
        $Global:Error | Should -Match 'not in a Git repository'
        $Global:Error | Should -Match ([regex]::Escape($env:TEMP))
    }

    It '-Verify switch is used and a repository in current directory isn''t found' {
        Push-Location -Path $env:TEMP
        try
        {
            $repo = Find-GitRepository -Verify -ErrorAction SilentlyContinue
            Assert-NoRepositoryReturned -Repository $repo
            $Global:Error | Should -Match 'not in a Git repository'
            $CurrentLocation = (Get-Location | Select-Object -ExpandProperty 'ProviderPath')
            $Global:Error | Should -Match ([regex]::Escape($CurrentLocation))
        }
        finally
        {
            Pop-Location
        }
    }

    It '-Verify switch is used and a repository is found' {
        $repo = Find-GitRepository -Path $PSScriptRoot -Verify
        Assert-ThisRepositoryFound -Repository $repo
        $Global:Error | Should -BeNullOrEmpty
    }
}