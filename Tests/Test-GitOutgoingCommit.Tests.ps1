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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

Describe 'Test-GitOutgoingCommit whithout the -All switch' {
    Clear-Error

    $remoteRepo = New-GitTestRepo
    Add-GitTestFile -RepoRoot $remoteRepo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file1') -RepoRoot $remoteRepo
    Save-GitChange -RepoRoot $remoteRepo -Message 'file1 commit'

    $localRepoPath = Join-Path -Path (Resolve-TestDrivePath) -ChildPath 'LocalRepo'
    Copy-GitRepository -Source $remoteRepo -DestinationPath $localRepoPath

    It 'should return false if there are no changes on the current branch' {
        Test-GitOutgoingCommit -RepoRoot $localRepoPath | Should Be $false
    }

    Add-GitTestFile -RepoRoot $localRepoPath -Path 'file2'
    Add-GitItem -Path (Join-Path $localRepoPath -ChildPath 'file2') -RepoRoot $localRepoPath
    Save-GitChange -RepoRoot $localRepoPath -Message 'file2 commit'

    It 'should return true if there are unpushed commits on the current branch' {
        Test-GitOutgoingCommit -RepoRoot $localRepoPath | Should Be $true
    }

    Assert-ThereAreNoErrors
}

Describe 'Test-GitOutgoingCommit with the -All switch' {
    Clear-Error

    $remoteRepo = New-GitTestRepo

    Add-GitTestFile -RepoRoot $remoteRepo -Path 'file1'
    Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file1') -RepoRoot $remoteRepo
    Save-GitChange -RepoRoot $remoteRepo -Message 'file1 commit on master'

    New-GitBranch -RepoRoot $remoteRepo -Name 'branch-2'
    Add-GitTestFile -RepoRoot $remoteRepo -Path 'file2'
    Add-GitItem -Path (Join-Path -Path $remoteRepo -ChildPath 'file2') -RepoRoot $remoteRepo
    Save-GitChange -RepoRoot $remoteRepo -Message 'file2 commit on branch-2'

    $localRepoPath = Join-Path -Path (Resolve-TestDrivePath) -ChildPath 'LocalRepo'
    Copy-GitRepository -Source $remoteRepo -DestinationPath $localRepoPath

    It 'should return false if there are no changes on any branch' {
        Test-GitOutgoingCommit -RepoRoot $localRepoPath -All | Should Be $false
    }

    # Make changes on branch-2
    Add-GitTestFile -RepoRoot $localRepoPath -Path 'file3'
    Add-GitItem -Path (Join-Path -Path $localRepoPath -ChildPath 'file3') -RepoRoot $localRepoPath
    Save-GitChange -RepoRoot $localRepoPath -Message 'file3 on branch-2'

    # Switch back to master by setting up local tracking branch
    New-GitBranch -RepoRoot $localRepoPath -Name 'master' -Revision 'remotes/origin/master'

    It 'should return true if there are unpushed commits on any branch' {
        Test-GitOutgoingCommit -RepoRoot $localRepoPath -All | Should Be $true
    }

    Assert-ThereAreNoErrors
}

Describe 'Test-GitOutgoingCommit when the given repo doesn''t exist' {
    Clear-Error

    Test-GitOutgoingCommit -RepoRoot 'C:\I\do\not\exist' -ErrorAction SilentlyContinue
    It 'should write an error' {
        $Global:Error.Count | Should Be 1
        $Global:Error | Should Match 'does not exist'
    }
}
 