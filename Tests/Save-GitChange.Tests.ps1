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

Describe 'Save-GitChange when committing changes' {
    $repoRoot = New-GitTestRepo
    Add-GitTestFile -Path 'file1' -RepoRoot $repoRoot
    Add-GitItem -Path 'file1' -RepoRoot $repoRoot
    $commit = Save-GitChange -Message 'fubar' -RepoRoot $repoRoot
    It 'should return a commit object' {
        $commit.pstypenames | Where-Object { $_ -eq 'LibGit2.Automation.CommitInfo' } | Should Not BeNullOrEmpty
    }
    It 'should commit everything' {
        git -C $repoRoot status --porcelain | Should BeNullOrEmpty
    }

    Context 'the commit object returned' {
        It 'should have an author' {
            $commit.Author | Should Not BeNullOrEmpty
            $commit.Committer | Should Not BeNullOrEmpty
            $commit.Committer | Should Be $commit.Author
        }
        It 'should have a message' {
            $commit.Message | Should Not BeNullOrEmpty
            $commit.MessageShort | Should Not BeNullOrEmpty
            $commit.Message | Should Be "fubar`n"
            $commit.MessageShort | Should Be 'fubar'
        }

        It 'should have an ID' {
            $commit.Id | Should Not BeNullOrEmpty
            $commit.Sha | Should Not BeNullOrEmpty
            $commit.Id | Should Be $commit.Sha
        }

        It 'should have an encoding' {
            $commit.Encoding | Should Be 'UTF-8'
        }
    }
}

Describe 'Save-GitChange when nothing to commit' {
    $repoRoot = New-GitTestRepo
    # First commit can be empty.
    Save-GitChange -Message 'fubar' -RepoRoot $repoRoot
    $commit = Save-GitChange -Message 'fubar' -RepoRoot $repoRoot -WarningVariable 'warnings'
    It 'should commit nothing' {
        $commit | Should BeNullOrEmpty
    }
    It 'should write a warning' {
        $warnings | Should Not BeNullOrEmpty
        $warnings | Should Match 'nothing to commit'
    }
}
