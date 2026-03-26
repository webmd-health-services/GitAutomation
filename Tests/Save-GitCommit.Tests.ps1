
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:repoNum = 0
    $script:repoRoot = $null
    [LibGit2Sharp.Signature]$script:signature = $null

    function GivenRepository
    {
        $script:repoRoot = Join-Path -Path $TestDrive -ChildPath ($script:repoNum++)
        New-GitRepository -Path $script:repoRoot | Format-List | Out-String | Write-Debug
        return $repoRoot
    }

    function GivenSignature
    {
        $script:signature = New-GitSignature -Name 'Fubar Snafu' -EmailAddress 'fizzbuzz@example.com'
    }
}

Describe 'Save-GitCommit' {
    BeforeAll {
        $script:repoRoot = $null
        $script:signature = $null
        $Global:Error.Clear()
    }

    It 'committing changes' {
        GivenRepository
        GivenSignature
        Add-GitTestFile -Path 'file1' -RepoRoot $script:repoRoot
        Add-GitItem -Path 'file1' -RepoRoot $script:repoRoot
        $commit = Save-GitCommit -Message 'fubar' -RepoRoot $script:repoRoot -Signature $script:signature
        $commit.pstypenames | Where-Object { $_ -eq 'Git.Automation.CommitInfo' } | Should -Not -BeNullOrEmpty
        git -C $script:repoRoot status --porcelain | Should -BeNullOrEmpty

        $commit.Author | Should -Not -BeNullOrEmpty
        $commit.Author.Email | Should -Be $script:signature.Email
        $commit.Author.Name | Should -Be $script:signature.Name
        $commit.Committer | Should -Not -BeNullOrEmpty
        $commit.Committer | Should -Be $commit.Author

        $commit.Message | Should -Not -BeNullOrEmpty
        $commit.MessageShort | Should -Not -BeNullOrEmpty
        $commit.Message | Should -Be "fubar`n"
        $commit.MessageShort | Should -Be 'fubar'

        $commit.Id | Should -Not -BeNullOrEmpty
        $commit.Sha | Should -Not -BeNullOrEmpty
        $commit.Id | Should -Be $commit.Sha

        $commit.Encoding | Should -Be 'UTF-8'
    }

    It 'nothing to commit' {
        GivenRepository
        GivenSignature
        Save-GitCommit -Message 'fubar' -RepoRoot $script:repoRoot -Signature $script:signature
        $commit = Save-GitCommit -Message 'fubar' -RepoRoot $script:repoRoot
        $commit | Should -BeNullOrEmpty
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'committing in the current directory' {
        GivenRepository
        Push-Location $script:repoRoot
        try
        {
            $commit = Save-GitCommit -Message 'fubar'
            $commit | Should -Not -BeNullOrEmpty

            $commit.Sha | Should -Be (Get-GitCommit -Revision $commit.Sha -RepoRoot $script:repoRoot).Sha
        }
        finally
        {
            Pop-Location
        }
    }
}