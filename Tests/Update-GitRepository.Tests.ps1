
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:testDirPath = $null
    $script:testNum = 0
    $script:repoNum = 0

    function GivenRepo
    {
        $repoRoot = Join-Path -Path $script:testDirPath -ChildPath ($script:repoNum++)
        New-GitRepository -Path $repoRoot | Format-List | Out-String | Write-Debug
        return $repoRoot
    }
}

Describe 'Update-GitRepository' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testDirPath -ItemType Directory
        $Global:Error.Clear()
    }

    It 'updating to a specific commit'{
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        Update-GitRepository -RepoRoot $repo -Revision $c1.Sha

        $r = Find-GitRepository -Path $repo
        try
        {
            $r.Head.Tip.Sha | Should -Be $c1.Sha
            (Get-GitBranch -RepoRoot $repo -Current).Name | Should -Match 'no branch'

        }
        finally
        {
            $r.Dispose()
        }

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'updating to a tag'{
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        New-GitTag -RepoRoot $repo -Name 'tag1' -Revision $c1.Sha
        $tag = Get-GitTag -RepoRoot $repo -Name 'tag1'

        Update-GitRepository -RepoRoot $repo -Revision $tag.CanonicalName

        $r = Find-GitRepository -Path $repo
        try
        {
            $r.Head.Tip.Sha | Should -Be $c1.Sha
            (Get-GitBranch -RepoRoot $repo -Current).Name | Should -Match 'no branch'

        }
        finally
        {
            $r.Dispose()
        }
    }

    It 'updating to a remote reference' {
        $remoteRepo = GivenRepo
        Add-GitTestFile -RepoRoot $remoteRepo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file1') -RepoRoot $remoteRepo
        $c1 = Save-GitCommit -RepoRoot $remoteRepo -Message 'file1 commit'

        $localRepoPath = Join-Path -Path $script:testDirPath -ChildPath 'LocalRepo'
        Copy-GitRepository -Source $remoteRepo -DestinationPath $localRepoPath

        Add-GitTestFile -RepoRoot $remoteRepo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file2') -RepoRoot $remoteRepo
        $c2 = Save-GitCommit -RepoRoot $remoteRepo -Message 'file2 commit'

        Receive-GitCommit -RepoRoot $localRepoPath

        Update-GitRepository -RepoRoot $localRepoPath -Revision 'refs/remotes/origin/master'

        $r = Find-GitRepository -Path $localRepoPath
        try
        {
            $r.Head.Tip.Sha | Should -Be $c2.Sha
            (Get-GitBranch -RepoRoot $localRepoPath -Current).Name | Should -Match 'no branch'
        }
        finally
        {
            $r.Dispose()
        }

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'updating to the head of a branch' {
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        $branch1Name = 'newbranch'
        New-GitBranch -RepoRoot $repo -Name $branch1Name -Revision $c1.Sha
        $branch1 = Get-GitBranch -RepoRoot $repo -Current
        New-GitBranch -RepoRoot $repo -Name 'newbranch2' -Revision $c2.Sha

        Update-GitRepository -RepoRoot $repo -Revision $branch1Name

        $r = Find-GitRepository -Path $repo
        try
        {
            $r.Head.CanonicalName | Should -Match $branch1.CanonicalName
            (Get-GitBranch -RepoRoot $repo -Current).Name | Should -Match $branch1.Name
        }
        finally
        {
            $r.Dispose()
        }

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'updating to a branch that only exists at the remote origin' {
        $remoteRepo = GivenRepo
        Add-GitTestFile -RepoRoot $remoteRepo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file1') -RepoRoot $remoteRepo
        $c1 = Save-GitCommit -RepoRoot $remoteRepo -Message 'file1 commit'
        New-GitBranch -RepoRoot $remoteRepo -Name 'develop' -Revision 'master'
        Update-GitRepository -RepoRoot $remoteRepo -Revision 'master'

        $localRepoPath = Join-Path -Path $script:testDirPath -ChildPath 'LocalRepo'
        Copy-GitRepository -Source $remoteRepo -DestinationPath $localRepoPath

        Update-GitRepository -RepoRoot $localRepoPath -Revision 'develop'

        $r = Find-GitRepository -Path $localRepoPath
        try
        {
            $originBranch = $r.Branches | Where-Object { $_.FriendlyName -eq 'origin/develop' }
            $localBranch = $r.Branches | Where-Object { $_.FriendlyName -eq 'develop' }

            $originBranch.IsRemote | Should -Be $true
            $localBranch.IsTracking | Should -Be $true
            $originBranch.CanonicalName | Should -Match $localBranch.TrackedBranch
        }
        finally
        {
            $r.Dispose()
        }

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'run with no parameters' {
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'
        try
        {
            Push-Location $repo
            $r = Find-GitRepository
            $head = $r.Head
            Update-GitRepository
            $r.Head | Should -Be $head

        }
        finally
        {
            Pop-Location
            $r.Dispose()
        }

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'the given repo does not exist' {
        Update-GitRepository -RepoRoot 'C:\I\do\not\exist' -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'does not exist'
    }

    It 'there are uncommitted changes' {
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        [Guid]::NewGuid() | Set-Content -Path (Join-Path -Path $repo -ChildPath 'file2')
        Update-GitRepository -RepoRoot $repo -Revision $c1.Sha -Force

        $status = Get-GitRepositoryStatus -RepoRoot $repo
        $status | Should -BeNullOrEmpty

        $r = Find-GitRepository -Path $repo
        try
        {
            $r.Head.Tip.Sha | Should -Be $c1.Sha
            (Get-GitBranch -RepoRoot $repo -Current).Name | Should -Match 'no branch'

        }
        finally
        {
            $r.Dispose()
        }

        $Global:Error | Should -BeNullOrEmpty
    }
}