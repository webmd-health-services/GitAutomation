
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:repoNum = 0

    function GivenRepo
    {
        $repoDirPath = Join-Path -Path $TestDrive -ChildPath ($script:repoNum++)
        New-GitRepository -Path $repoDirPath | Format-List | Out-String | Write-Debug
        return $repoDirPath
    }
}

Describe 'Get-GitBranch' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'using the -Current switch' {
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        $branch = Get-GitBranch -RepoRoot $repo -Current
        $branch.Name | Should -Be 'master'
        $branch.Tip.Sha | Should -Be $c1.Sha
        $branch.IsCurrentRepositoryHead | Should -Be $true

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'without the -Current switch' {
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        New-GitBranch -RepoRoot $repo -Name 'branch2'
        New-GitBranch -RepoRoot $repo -Name 'branch3'

        $branches = Get-GitBranch -RepoRoot $repo

        # Returns in lexicographical order
        $branches | ForEach-Object { $_.Tip.Sha | Should -Be $c1.Sha }
        $branches[0].Name | Should -Be 'branch2'
        $branches[0].IsCurrentRepositoryHead | Should -Be $false
        $branches[1].Name | Should -Be 'branch3'
        $branches[1].IsCurrentRepositoryHead | Should -Be $true
        $branches[2].Name | Should -Be 'master'
        $branches[2].IsCurrentRepositoryHead | Should -Be $false
    }

    It 'passed an invalid repository'{
        $branches = Get-GitBranch -RepoRoot 'C:\I\do\not\exist' -ErrorAction SilentlyContinue

        $branches | Should -BeNullOrEmpty
        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'does not exist'
    }
}