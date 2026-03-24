
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:testDirPath = $null
    $script:testNum = 0

    function GivenRepo
    {
        New-GitRepository -Path $script:testDirPath | Format-List | Out-String | Write-Debug
        return $script:testDirPath
    }

    function ThenError
    {
        param(
            [switch] $Empty
        )

        $Global:Error | Should -BeNullOrEmpty
    }
}

Describe 'Get-GitTag' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testDirPath -ItemType Directory

        $Global:Error.Clear()
    }

    It 'gets all tags' {
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        New-GitTag -RepoRoot $repo -Name 'tag1' -Revision $c1.Sha
        New-GitTag -RepoRoot $repo -Name 'tag2' -Revision $c2.Sha
        $tags = Get-GitTag -RepoRoot $repo

        $tags.Count | Should -Be 2
        $tags[0].Name | Should -Be 'tag1'
        $tags[0].Sha | Should -Be $c1.Sha
        $tags[1].Name | Should -Be 'tag2'
        $tags[1].Sha | Should -Be $c2.Sha

        ThenError -Empty
    }

    It 'gets specific tag' {
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        New-GitTag -RepoRoot $repo -Name 'tag1' -Revision $c1.Sha
        New-GitTag -RepoRoot $repo -Name 'tag2' -Revision $c2.Sha
        $tags = Get-GitTag -RepoRoot $repo -Name 'tag1'

        $tags | Should -Not -BeNullOrEmpty
        $tags.Name | Should -Be 'tag1'
        $tags.Sha | Should -Be $c1.Sha

        ThenError -Empty
    }

    It 'handles no tag' {
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        New-GitTag -RepoRoot $repo -Name 'tag1' -Revision $c1.Sha
        New-GitTag -RepoRoot $repo -Name 'tag2' -Revision $c2.Sha
        $tags = Get-GitTag -RepoRoot $repo -Name 'tag3'

        $tags | Should -BeNullOrEmpty

        ThenError -Empty
    }

    It 'supports wildcard' {
        $repo = GivenRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        New-GitTag -RepoRoot $repo -Name 'tag1' -Revision $c1.Sha
        New-GitTag -RepoRoot $repo -Name 'tag2' -Revision $c2.Sha
        New-GitTag -RepoRoot $repo -Name 'anotherTag' -Revision $c1.Sha
        $tags = Get-GitTag -RepoRoot $repo -Name 'tag*'

        $tags.Count | Should -Be 2
        $tags[0].Name | Should -Be 'tag1'
        $tags[0].Sha | Should -Be $c1.Sha
        $tags[1].Name | Should -Be 'tag2'
        $tags[1].Sha | Should -Be $c2.Sha

        ThenError -Empty
    }

    It 'validates repository exists'{
        Get-GitTag -RepoRoot 'C:/I/do/not/exist' -Name 'whocares' -ErrorAction SilentlyContinue

        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'does not exist'
    }
}