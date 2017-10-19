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

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-LibGit2Test.ps1' -Resolve)

function GivenRemoteRepository
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )
    
    $script:remoteRepoPath = (Join-Path -Path $TestDrive -ChildPath $Path)
    New-GitRepository -Path $remoteRepoPath | Out-Null
    Set-GitConfiguration -Name 'core.bare' -Value 'true' -RepoRoot $remoteRepoPath
}

function GivenLocalRepositoryTracksRemote
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )
    
    $script:localRepoPath = (Join-Path -Path $TestDrive -ChildPath $Path)
    Copy-GitRepository -Source $remoteRepoPath -DestinationPath $localRepoPath
}

function GivenLocalRepositoryWithNoRemote
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )
    
    $script:localRepoPath = (Join-Path -Path $TestDrive -ChildPath $Path)
    New-GitRepository -Path $localRepoPath | Out-Null
}

function GivenCommittedChangeToPush
{
    param(
    )
    
    Add-GitTestFile -RepoRoot $localRepoPath -Path 'TestFile.txt'
    Add-GitItem -RepoRoot $localRepoPath -Path 'TestFile.txt'
    Save-GitChange -RepoRoot $localRepoPath -Message 'Adding test file'
}

function WhenSynchronizingGitRepository
{
    param(
    )

    $Global:Error.Clear()

    Sync-GitRepository -RepoRoot $localRepoPath -ErrorAction SilentlyContinue
}

function ThenNoErrorsWereThrown
{
    param(
    )

    It 'should not throw any errors' {
        $Global:Error | Should BeNullOrEmpty
    }
}

function ThenErrorWasThrown
{
    param(
        [string]
        $ErrorMessage
    )

    It ('should throw an error: ''{0}''' -f $ErrorMessage) {
        $Global:Error | Should Match $ErrorMessage
    }
}

function ThenRepositoriesAreSynced
{
    param(
    )

    It 'local repository should not have any unstaged changes' {
        Test-GitUncommittedChange -RepoRoot $localRepoPath | Should Be $false
    }
    
    It 'local repository should not have any outgoing commits' {
        Test-GitOutgoingCommit -RepoRoot $localRepoPath | Should Be $false
    }

    It 'the HEAD commit of the local repository should match the remote repository' {
        (Get-GitCommit -RepoRoot $remoteRepoPath -Revision HEAD).Sha | Should Be (Get-GitCommit -RepoRoot $localRepoPath -Revision HEAD).Sha
    }
}

Describe 'Sync-GitRepository.when pushing changes to a remote repository' {
    GivenRemoteRepository 'RemoteRepo'
    GivenLocalRepositoryTracksRemote 'LocalRepo'
    GivenCommittedChangeToPush
    WhenSynchronizingGitRepository
    ThenNoErrorsWereThrown
    ThenRepositoriesAreSynced
}

Describe 'Sync-GitRepository.when no upstream remote is defined' {
    GivenLocalRepositoryWithNoRemote 'LocalRepo'
    GivenCommittedChangeToPush
    WhenSynchronizingGitRepository
    ThenErrorWasThrown 'No upstream remote is configured for ''master'' branch. Aborting synchronization.'
}
