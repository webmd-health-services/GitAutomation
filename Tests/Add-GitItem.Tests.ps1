
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    function Assert-FileNotStaged
    {
        param(
            [string[]]
            $Path,

            [string]
            $RepoRoot = (Get-Location).ProviderPath
        )

        foreach( $pathItem in $Path )
        {
            Get-GitRepositoryStatus -RepoRoot $RepoRoot -Path $pathItem |
                Where-Object { $_.IsStaged } |
                Should -BeNullOrEmpty
        }
    }
    function Assert-FileStaged
    {
        param(
            [string[]]
            $Path,

            [string]
            $RepoRoot = (Get-Location).ProviderPath
        )

        foreach( $pathItem in $Path )
        {
            Get-GitRepositoryStatus -RepoRoot $RepoRoot -Path $pathItem |
                Where-Object { $_.IsStaged } |
                Measure-Object |
                Select-Object -ExpandProperty 'Count' |
                Should -Be 1
        }
    }
}

Describe 'Add-GitItem' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should add new files' {
        $repoRoot = New-GitTestRepo
        Add-GitTestFile -RepoRoot $repoRoot -Path 'file1','file2','file3','file4'
        Add-GitItem -Path (Join-Path -Path $repoRoot -ChildPath 'file1'),(Join-Path -Path $repoRoot -ChildPath 'file2') `
                    -RepoRoot $repoRoot

        Assert-FileStaged -Path 'file1','file2' -RepoRoot $repoRoot
        Assert-FileNotStaged -Path 'file3','file4' -RepoRoot $repoRoot
    }

    It 'should add new files from the current directory' {
        $repoRoot = New-GitTestRepo
        Push-Location $repoRoot
        try
        {
            Add-GitTestFile -Path 'file1','file2','file3','file4'
            Add-GitItem -Path 'file1','file2'

            Assert-FileStaged 'file1','file2'
            Assert-FileNotStaged 'file3','file4'
        }
        finally
        {
            Pop-Location
        }
    }

    It 'should write an error if paths aren''t under the repository' {
        $repoRoot = New-GitTestRepo
        $anotherRepo = New-GitTestRepo
        $relativePath = Join-Path -Path ('..\{0}' -f (Split-Path -Leaf -Path $anotherRepo)) `
                                  -ChildPath ([IO.Path]::GetRandomFileName())
        '' | Set-Content -Path (Join-Path -Path $anotherRepo -ChildPath (Split-Path -Leaf -Path $relativePath))
        $fullPath = Join-Path -Path $anotherRepo -ChildPath ([IO.Path]::GetRandomFileName())
        '' | Set-Content -Path $fullPath

        Add-GitItem -Path $relativePath,$fullPath -RepoRoot $repoRoot -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -Be 2
        $Global:Error | Should -Match 'not in the repository'
    }

    It 'paths to add do not exist' {
        $repoRoot = New-GitTestRepo
        $relativePath = Join-Path -Path '..' -ChildPath ([IO.Path]::GetRandomFileName())
        $fullPath = Join-Path -Path $repoRoot -ChildPath ([IO.Path]::GetRandomFileName())

        Add-GitItem -Path $relativePath,$fullPath -RepoRoot $repoRoot -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -Be 2
        $Global:Error | Should -Match 'does not exist'
    }

    It 'passed a relative repository root path' {
        $repoRoot = New-GitTestRepo
        Push-Location -Path (Split-Path -Parent -Path $repoRoot)
        try
        {
            Add-GitTestFile -RepoRoot $repoRoot -Path 'file1'
            Add-GitItem -Path 'file1' -RepoRoot (Split-Path -Leaf -Path $repoRoot)
            Assert-FileStaged -Path 'file1' -RepoRoot $repoRoot
        }
        finally
        {
            Pop-Location
        }
    }

    It 'repository does not exist' {
        Add-GitItem -RepoRoot 'C:\I\do\not\exist' -Path 'meneither' -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'does not exist'
    }

    It 'repository is not a repository' {
        Push-Location -Path 'TestDrive:'
        try
        {
            '' | Set-Content 'file1'
            Add-GitItem -Path 'file1' -ErrorAction SilentlyContinue
            $Global:Error.Count | Should -BeGreaterThan 0
            $Global:Error | Should -Match 'not in a Git repository'
        }
        finally
        {
            Pop-Location
        }
    }

    It 'supports pipeline input' {
        $repoRoot = New-GitTestRepo
        Add-GitTestFile 'file1','file2','dir1\file3','dir1\file4' -RepoRoot $repoRoot
        ('file1',(Get-Item -Path (Join-Path -Path $repoRoot -ChildPath 'file2')),(Get-Item -Path (Join-Path -Path $repoRoot -ChildPath 'dir1'))) |
            Add-GitItem -RepoRoot $repoRoot
        Assert-FileStaged 'file1','file2','dir1\file3','dir1\file4' -RepoRoot $repoRoot
    }

    It 'returns item object' {
        $repoRoot = New-GitTestRepo
        Add-GitTestFile -Path 'file1','dir1\file2' -RepoRoot $repoRoot
        $result = Add-GitItem -RepoRoot $repoRoot -Path 'file1','dir1' -PassThru
        Assert-FileStaged 'file1','dir1\file2' -RepoRoot $repoRoot
        $result.Count | Should -Be 2
        $result[0] | Should -BeOfType ([IO.FileInfo])
        $result[0].Name | Should -Be 'file1'
        $result[1] | Should -BeOfType ([IO.DirectoryInfo])
        $result[1].Name | Should -Be 'dir1'
    }

    It 'item is already added' {
        $repoRoot = New-GitTestRepo
        Add-GitTestFile -Path 'file1' -RepoRoot $repoRoot
        Add-GitItem -Path 'file1','file1' -RepoRoot $repoRoot
        Assert-FileStaged -Path 'file1' -RepoRoot $repoRoot
        $Global:Error.Count | Should -Be 0
    }

    It 'for an unmodified file' {
        $repoRoot = New-GitTestRepo
        Add-GitTestFile -Path 'file1' -RepoRoot $repoRoot
        Add-GitItem -Path 'file1','file1' -RepoRoot $repoRoot
        Save-GitCommit -Message 'Committing a file change' -RepoRoot $repoRoot
        Add-GitItem -Path 'file1' -RepoRoot $repoRoot
        Assert-FileNotStaged -Path 'file1' -RepoRoot $repoRoot
        $Global:Error.Count | Should -Be 0
    }
}
