
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)
}

Describe 'Get-GitRepositoryStatus' {
    It 'getting status' {
        $repoRoot = New-GitTestRepo

        $modifiedPath = Join-Path -Path $repoRoot -ChildPath 'modified'
        '' | Set-Content -Path $modifiedPath

        $renamedPath = Join-Path -Path $repoRoot -ChildPath 'renamed'
        '' | Set-Content -Path $renamedPath

        $removedPath = Join-Path -Path $repoRoot -ChildPath 'removed'
        '' | Set-Content -Path $removedPath

        $missingPath = Join-Path -Path $repoRoot -ChildPath 'missing'
        '' | Set-Content -Path $missingPath

        $status = Get-GitRepositoryStatus -RepoRoot $repoRoot
        $status |
            Select-Object -ExpandProperty 'State' |
            ForEach-Object { $_ | Should -Be ([LibGit2Sharp.FileStatus]::NewInWorkdir) }

        Add-GitItem -Path $modifiedPath -RepoRoot $repoRoot
        Add-GitItem -Path $renamedPath -RepoRoot $repoRoot
        Add-GitItem -Path $removedPath -RepoRoot $repoRoot
        Add-GitItem -Path $missingPath -RepoRoot $repoRoot

        $status = Get-GitRepositoryStatus -RepoRoot $repoRoot
        $status |
            Where-Object { $_.FilePath -ne 'untracked' } |
            Select-Object -ExpandProperty 'State' |
            ForEach-Object { $_ |  Should -Be ([LibGit2Sharp.FileStatus]::NewInIndex) }

        Save-GitCommit -Message 'testing status' -RepoRoot $repoRoot

        'modified' | Set-Content -Path $modifiedPath

        Get-GitRepositoryStatus -RepoRoot $repoRoot |
            Where-Object { $_.FilePath -eq 'modified' } |
            Select-Object -ExpandProperty 'State' | Should -Be ([LibGit2Sharp.FileStatus]::ModifiedInWorkdir)

        Add-GitItem -Path $modifiedPath -RepoRoot $repoRoot
        Get-GitRepositoryStatus -RepoRoot $repoRoot |
            Where-Object { $_.FilePath -eq 'modified' } |
            Select-Object -ExpandProperty 'State' | Should -Be ([LibGit2Sharp.FileStatus]::ModifiedInIndex)

        git -C $repoRoot rm $removedPath
        Get-GitRepositoryStatus -RepoRoot $repoRoot |
            Where-Object { $_.FilePath -eq 'removed' } |
            Select-Object -ExpandProperty 'State' | Should -Be ([LibGit2Sharp.FileStatus]::DeletedFromIndex)

        Remove-Item -Path $missingPath
        Get-GitRepositoryStatus -RepoRoot $repoRoot |
            Where-Object { $_.FilePath -eq 'missing' } |
            Select-Object -ExpandProperty 'State' | Should -Be ([LibGit2Sharp.FileStatus]::DeletedFromWorkdir)

        git -C $repoRoot mv $renamedPath (Join-Path -Path $repoRoot -ChildPath 'renamed2')
        $status = Get-GitRepositoryStatus -RepoRoot $repoRoot
        $status |
            Where-Object { $_.FilePath -eq 'renamed' } |
            Select-Object -ExpandProperty 'State' |
            Should -Be ([LibGit2Sharp.FileStatus]::DeletedFromIndex)
        $status |
            Where-Object { $_.FilePath -eq 'renamed2' } |
            Select-Object -ExpandProperty 'State' |
            Should -Be ([LibGit2Sharp.FileStatus]::RenamedInIndex)
    }

    It 'items are ignored' {
        $repoRoot = New-GitTestRepo
        "file1`ndir1" | Set-Content -Path (Join-Path -Path $repoRoot -ChildPath '.gitignore')
        '' | Set-Content -Path (Join-Path -Path $repoRoot -ChildPath 'file1')

        $dir1Path = Join-Path -Path $repoRoot -ChildPath 'dir1'
        New-Item -Path $dir1Path -ItemType 'Directory'
        '' | Set-Content -Path (Join-Path -Path $dir1Path -ChildPath 'file2') -Force

        Get-GitRepositoryStatus -RepoRoot $repoRoot | Select-Object -ExpandProperty 'FilePath' | Should -Be '.gitignore'

        $status = Get-GitRepositoryStatus -RepoRoot $repoRoot -IncludeIgnored
        $status | Where-Object { $_.FilePath -eq '.gitignore' } | Should -Not -BeNullOrEmpty
        $status | Where-Object { $_.FilePath -eq 'file1' } | Should -Not -BeNullOrEmpty
        $status | Where-Object { $_.FilePath -eq 'dir1/file2' } | Should -Not -BeNullOrEmpty
    }

    It 'run without a repo root parameter' {
        $repoRoot = New-GitTestRepo
        '' | Set-Content -Path (Join-Path -Path $repoRoot -ChildPath 'file1')
        $subDir = Join-Path -Path $repoRoot -ChildPath 'dir1'
        New-Item -Path $subDir -ItemType 'Directory'
        '' | Set-Content -Path (Join-Path -Path $subDir -ChildPath 'file2')
        Push-Location -Path $subDir
        try
        {
            $status = Get-GitRepositoryStatus
            $status | Where-Object { $_.FilePath -eq 'file1' } | Should -Not -BeNullOrEmpty
            $status | Where-Object { $_.FilePath -eq 'dir1/file2' } | Should -Not -BeNullOrEmpty
        }
        finally
        {
            Pop-Location
        }
    }

    It 'getting status of explicit paths' {
        $repoRoot = New-GitTestRepo
        $file1Path = Join-Path -Path $repoRoot -ChildPath 'file1'
        '' | Set-Content -Path $file1Path
        '' | Set-Content -Path (Join-Path -Path $repoRoot -ChildPath 'file2')
        '' | Set-Content -Path (Join-Path -Path $repoRoot -ChildPath 'file3')

        Get-GitRepositoryStatus -RepoRoot $repoRoot -Path $file1Path |
            Select-Object -ExpandProperty 'FilePath' |
            Should -Be 'file1'

        Push-Location -Path $repoRoot
        try
        {
            Get-GitRepositoryStatus -Path 'file1' | Select-Object -ExpandProperty 'FilePath' | Should -Be 'file1'
            Get-GitRepositoryStatus -Path 'file1','file2' |
                Select-Object -ExpandProperty 'FilePath' |
                Should -Match 'file(1|2)'
            Get-GitRepositoryStatus -Path '*1' | Select-Object -ExpandProperty 'FilePath' | Should -Be 'file1'

            $dir1Path = Join-Path -Path $repoRoot -ChildPath 'dir1'
            New-Item -Path $dir1Path -ItemType 'directory'
            Push-Location -Path $dir1Path
            try
            {
                '' | Set-Content -Path 'file4'
                Get-GitRepositoryStatus '.' | Select-Object -ExpandProperty 'FilePath' | Should -Be 'dir1/file4'

                $status = Get-GitRepositoryStatus '..'
                $status |
                    Select-Object -ExpandProperty 'FilePath' |
                    Where-Object { $_ -match 'file(1|2|3)$' } | Should -Not -BeNullOrEmpty
                $status |
                    Select-Object -ExpandProperty 'FilePath' |
                    Where-Object { $_ -match 'file4$' } | Should -Not -BeNullOrEmpty
            }
            finally
            {
                Pop-Location
            }

            Get-GitRepositoryStatus 'dir1/file4' | Select-Object -ExpandProperty 'FilePath' | Should -Not -BeNullOrEmpty
        }
        finally
        {
            Pop-Location
        }

        $dir2Path = Join-Path -Path $repoRoot -ChildPath 'dir2'
        New-Item -Path $dir2Path -ItemType 'directory'
        '' | Set-Content -Path (Join-Path -Path $dir2Path -ChildPath 'file4')
        Get-GitRepositoryStatus 'dir2' -RepoRoot $repoRoot |
            Select-Object -ExpandProperty 'FilePath' |
            Should -Be 'dir2/file4'
    }
}
