
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
        $repoRoot = Join-Path -Path $script:testDirPath -ChildPath $script:repoNum
        New-GitRepository -Path $repoRoot | Format-List | Out-String | Write-Debug
        return $repoRoot
    }
}

Describe 'New-GitBranch' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testDirPath -ItemType Directory
        $Global:Error.Clear()
    }

    It 'creating a new unique branch' {
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        $branchName = 'newBranch'
        Test-GitBranch -RepoRoot $repo -Name $branchName | Should -BeFalse
        New-GitBranch -RepoRoot $repo -Name $branchName

        Test-GitBranch -RepoRoot $repo -Name $branchName | Should -BeTrue

        (Get-GitBranch -RepoRoot $repo -Current).Name | Should -Be $branchName

        $r = Find-GitRepository -Path $repo
        try
        {
            (Get-GitBranch -RepoRoot $repo -Current).Name | Should -Be $r.Head.FriendlyName
        }
        finally
        {
            $r.Dispose()
        }

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'trying to create an existing branch name' {
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        $branchName = 'master'
        Test-GitBranch -RepoRoot $repo -Name $branchName | Should -BeTrue
        New-GitBranch -RepoRoot $repo -Name $branchName -WarningVariable warning

        $warning | Should -Match 'already exists'
        Test-GitBranch -RepoRoot $repo -Name $branchName | Should -BeTrue

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'ran with an invalid git repository' {
        New-GitBranch -RepoRoot 'C:/I/do/not/exist' -Name 'whocares' -ErrorAction SilentlyContinue

        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'does not exist'
    }

    It 'passing a start point that is not head' {
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        $branchName = 'newBranch'
        Test-GitBranch -RepoRoot $repo -Name $branchName | Should -BeFalse
        New-GitBranch -RepoRoot $repo -Name $branchName -Revision 'HEAD~1'

        Test-GitBranch -RepoRoot $repo -Name $branchName | Should -BeTrue

        (Get-GitBranch -RepoRoot $repo -Current).Name | Should -Be $branchName

        (Get-GitBranch -RepoRoot $repo -Current).Tip.Sha | Should -Be $c1.Sha
    }

    It 'passing an invalid start point'{
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        $branchName = 'newBranch'
        $startPoint = 'IDONOTEXIST'
        Test-GitBranch -RepoRoot $repo -Name $branchName | Should -BeFalse
        New-GitBranch -RepoRoot $repo -Name $branchName -Revision $startPoint -ErrorAction SilentlyContinue

        $Global:Error[0] | Should -Match 'invalid starting point'

        Test-GitBranch -RepoRoot $repo -Name $branchName | Should -BeFalse
    }
}
