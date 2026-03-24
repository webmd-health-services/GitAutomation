
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)
}

Describe 'New-GitTag' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'creating a new unique tag without passing a target' {
        $repo = New-GitTestRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        $tagName = 'TAAAAAGGGGG'
        Test-GitTag -RepoRoot $repo -Name $tagName | Should -BeFalse
        New-GitTag -RepoRoot $repo -Name $tagName


        Test-GitTag -RepoRoot $repo -Name $tagName | Should -BeTrue

        $r = Find-GitRepository -Path $repo
        try
        {
            (Get-GitTag -RepoRoot $repo -Name $tagName).Sha | Should -Be $r.Head.Tip.Sha
        }
        finally
        {
            $r.Dispose()
        }

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'creating a new unique tag and passing a revision'{
        $repo = New-GitTestRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        $tagName = 'aNOTHER---ONNEEE!!!'
        Test-GitTag -RepoRoot $repo -Name $tagName | Should -BeFalse
        New-GitTag -RepoRoot $repo -Name $tagName -Revision $c1.Sha

        Test-GitTag -RepoRoot $repo -Name $tagName | Should -BeTrue

        (Get-GitTag -RepoRoot $repo -Name $tagName).Sha | Should -Be $c1.Sha

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'passing a name of a tag that already exists without using -Force' {
        $repo = New-GitTestRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        $tagName = 'duplicate'
        New-GitTag -RepoRoot $repo -Name $tagName
        Test-GitTag -RepoRoot $repo -Name $tagName | Should -BeTrue

        New-GitTag -RepoRoot $repo -Name $tagName -ErrorAction SilentlyContinue

        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'already exists'
    }

    It 'using the -Force switch to overwrite a tag'{
        $repo = New-GitTestRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        $tagName = 'tag'
        New-GitTag -RepoRoot $repo -Name $tagName -Revision $c1.Sha
        Test-GitTag -RepoRoot $repo -Name $tagName | Should -BeTrue

        New-GitTag -RepoRoot $repo -Name $tagName -Revision $c2.Sha -Force

        Test-GitTag -RepoRoot $repo -Name $tagName | Should -BeTrue
        (Get-GitTag -RepoRoot $repo -Name $tagName).Sha | Should -Be $c2.Sha

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'creating a new tag for a revision that is already tagged'{
        $repo = New-GitTestRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        Add-GitTestFile -RepoRoot $repo -Path 'file2'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file2') -RepoRoot $repo
        $c2 = Save-GitCommit -RepoRoot $repo -Message 'file2 commit'

        $tag1 = 'tag1'
        $tag2 = 'tag2'
        New-GitTag -RepoRoot $repo -Name $tag1 -Revision $c1.Sha
        New-GitTag -RepoRoot $repo -Name $tag2 -Revision $c1.Sha

        Test-GitTag -RepoRoot $repo -Name $tag2 | Should -BeTrue
        (Get-GitTag -RepoRoot $repo -Name $tag2).Sha | Should -Be $c1.Sha

        Test-GitTag -RepoRoot $repo -Name $tag1 | Should -BeTrue
        (Get-GitTag -RepoRoot $repo -Name $tag1).Sha | Should -Be $c1.Sha

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'passing an invalid revision' {
        $repo = New-GitTestRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        New-GitTag -RepoRoot $repo -Name 'whocares' -Revision 'IdoNotExist' -ErrorAction SilentlyContinue

        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'No valid git object'
    }

    It 'ran with an invalid git repository'{
        New-GitTag -RepoRoot 'C:/I/do/not/exist' -Name 'whocares' -ErrorAction SilentlyContinue

        $Global:Error.Count | Should -Be 1
        $Global:Error | Should -Match 'does not exist'
    }
}