
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:testDirPath = $null
    $script:testNum = 0

    function Assert-Repository
    {
        param(
            [Parameter(Position=0)]
            $Repository,
            $CreatedAt
        )

        $Repository | Should -Not -BeNullOrEmpty
        $Repository | Should -BeOfType ([Git.Automation.RepositoryInfo])
        $Repository.WorkingDirectory.TrimEnd('\', '/') | Should -Be $CreatedAt.TrimEnd('\', '/')
        $Repository.Path | Should -Be (Join-Path -Path $CreatedAt -ChildPath '.git\')
    }

    function ThenDirectory
    {
        param(
            $Path,
            [switch] $Exists,
            [switch] $DoesNotExist
        )

        $fullPath = Join-Path -Path $script:testDirPath -ChildPath $Path
        if( $Exists )
        {
            $fullPath | Should -Exist
        }
        else
        {
            $fullPath | Should -Not -Exist
        }
    }

    function ThenFile
    {
        param(
            $Path,
            $MatchesRegex
        )

        $fullPath = Join-Path -Path $script:testDirPath -ChildPath $Path

        Get-Content -Raw -Path $fullPath | Should -Match $MatchesRegex
    }

    function WhenCreatingRepo
    {
        param(
            [switch] $Bare
        )

        New-GitRepository -Path $script:testDirPath -Bare:$Bare
    }
}

Describe 'New-GitRepository' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testDirPath -ItemType Directory
        $Global:Error.Clear()
    }

    It 'path does not exist' {
        $repoRoot = Join-Path -Path $script:testDirPath -ChildPath 'parent\reporoot\'
        $repo = New-GitRepository -Path $repoRoot
        Assert-Repository $repo -CreatedAt $repoRoot
    }

    It 'path is relative' {
        $repoRoot = 'parent\reporoot\'
        Push-Location -Path $script:testDirPath
        try
        {
            $repo = New-GitRepository -Path $repoRoot
            Assert-Repository $repo -CreatedAt (Join-Path -Path $script:testDirPath -ChildPath $repoRoot)
        }
        finally
        {
            Pop-Location
        }
    }

    It 'path exists' {
        $repo = New-GitRepository -Path $script:testDirPath
        Assert-Repository $repo -CreatedAt $script:testDirPath
    }

    It 'path is already a repository' {
        $repo = New-GitRepository -Path $script:testDirPath
        Assert-Repository $repo -CreatedAt $script:testDirPath
        $repo = New-GitRepository -Path $script:testDirPath
        Assert-Repository $repo -CreatedAt $script:testDirPath
    }

    It '-WhatIf switch is passed' {
        $repo = New-GitRepository -Path $script:testDirPath -WhatIf
        $repo | Should -BeNullOrEmpty
        Get-ChildItem -Path $script:testDirPath | Should -BeNullOrEmpty
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'creating bare repository' {
        WhenCreatingRepo -Bare
        ThenDirectory '.git' -DoesNotExist
        ThenDirectory 'refs' -Exists
        ThenFile 'config' -Matches 'bare\ =\ true'
    }
}
