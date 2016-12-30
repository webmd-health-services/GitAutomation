# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
    
& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-LibGit2Test.ps1' -Resolve)

function Assert-IsHeadCommit
{
    param(
        $Commit,
        $RepoRoot
    )
    It 'should get the current HEAD' {
        $Commit.Sha | Should Be (Get-Content -Path (Join-Path -Path $RepoRoot -ChildPath '.git\refs\heads\master'))
    }
}

function New-TestRepository
{
    param(
        [int]
        $NumCommits = 1
    )

    $repoRoot = (Get-Item -Path 'TestDrive:').FullName

    New-GitRepository -Path $repoRoot | Out-Null

    $filePath = Join-Path -Path $repoRoot -ChildPath 'file'
    '0' | Set-Content -Path $filePath
    Add-GitItem -Path $filePath -RepoRoot $repoRoot | Out-Null
    Save-GitChange -Message '0' -RepoRoot $repoRoot | Out-Null
    for( $idx = 1; $idx -lt $NumCommits; ++$idx )
    {
        # Git uses second-granularity timestamps
        Start-Sleep -Seconds 1
        $idx | Set-Content -Path $filePath
        Add-GitItem -Path $filePath -RepoRoot $repoRoot
        Save-GitChange -Message $idx -RepoRoot $repoRoot | Out-Null
    }

    $repoRoot
}

Describe 'Get-GitCommit when run with no parameters' {
    $repoRoot = New-TestRepository -NumCommits 10

    $commits = Get-GitCommit -RepoRoot $repoRoot

    It 'should return all commits' {
        $commits.Count | Should Be 10
        $commits = $commits | Sort-Object -Property { $_.Author.When } -Descending
        for( $idx = 0; $idx -lt 10; ++$idx )
        {
            $commits[$idx].MessageShort | Should Be (9 - $idx)
        }
    }

}

Describe 'Get-GitCommit when asking for a specific revision' {
    $repoRoot = New-TestRepository 

    $commit = Get-GitCommit -Revision 'HEAD' -RepoRoot $repoRoot

    Assert-IsHeadCommit -Commit $commit -RepoRoot $repoRoot
}

Describe 'Get-GitCommit when named revision doesn''t exist' {
    $repoRoot = New-TestRepository 
    $Global:Error.Clear()

    $commit = Get-GitCommit -Revision 'FUBARSNAFU' -RepoRoot $repoRoot -ErrorAction SilentlyContinue
    It 'should return nothing' {
        $commit | Should BeNullOrEmpty
    }
    It 'should write an error' {
        $Global:Error | Should Match 'not\ found'
    }
}


Describe 'Get-GitCommit when ignoring errors and a commit does not exist' {
    $repoRoot = New-TestRepository 
    $commit = Get-GitCommit -Revision 'FUBARSNAFU' -RepoRoot $repoRoot -ErrorAction Ignore
    $Global:Error.Clear()
    It 'should return nothing' {
        $commit | Should BeNullOrEmpty
    }
    It 'should write an error' {
        $Global:Error.Count | Should Be 0
    }
}

Describe 'Get-GitCommit when using default repository' {
    $repoRoot = New-TestRepository 
    Push-Location -Path $repoRoot
    try
    {
        $commit = Get-GitCommit -Revision 'HEAD'

        It 'should return a commit' {
            $commit | Should Not BeNullOrEmpty
        }

        Assert-IsHeadCommit -Commit $commit -RepoRoot $repoRoot
    }
    finally
    {
        Pop-Location
    }    
}