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
    Add-GitTestFile -RepoRoot $remoteRepoPath -Path 'InitialCommit.txt'
    Add-GitItem -RepoRoot $remoteRepoPath -Path 'InitialCommit.txt'
    Save-GitChange -RepoRoot $remoteRepoPath -Message 'Initial Commit'
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

function GivenTag
{
    param(
        $Name
    )

    New-GitTag -RepoRoot $localRepoPath -Name $Name
}

function GivenCommittedChangeToPush
{
    param(
    )
    
    Add-GitTestFile -RepoRoot $localRepoPath -Path 'LocalTestFile.txt'
    Add-GitItem -RepoRoot $localRepoPath -Path 'LocalTestFile.txt'
    Save-GitChange -RepoRoot $localRepoPath -Message 'Adding local test file to local repo'
}

function GivenRemoteContainsOtherChanges
{
    param(
    )
    
    Set-GitConfiguration -Name 'core.bare' -Value 'false' -RepoRoot $remoteRepoPath
    Add-GitTestFile -RepoRoot $remoteRepoPath -Path 'RemoteTestFile.txt'
    Add-GitItem -RepoRoot $remoteRepoPath -Path 'RemoteTestFile.txt'
    Save-GitChange -RepoRoot $remoteRepoPath -Message 'Adding remote test file to remote repo'
    Set-GitConfiguration -Name 'core.bare' -Value 'true' -RepoRoot $remoteRepoPath
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

function ThenRemoteContainsLocalCommits
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

function ThenRemoteHasRevision
{
    param(
        $Revision
    )

    It ('should push refspec to remote') {
        Test-GitCommit -RepoRoot $remoteRepoPath -Revision $Revision | Should -Be $true
    }
}

function ThenPushResultIs
{
    param(
        $PushStatus
    )

    It ('function returned status of ''{0}''' -f $script:pushResult) {
        $script:pushResult | Should Be $PushStatus
    }
}

function WhenSendingObject
{
    [CmdletBinding()]
    param(
        $RefSpec
    )

    $Global:Error.Clear()
    $script:pushResult = $null
    
    $script:pushResult = Send-GitObject -RepoRoot $localRepoPath -RefSpec $RefSpec
}

Describe 'Send-GitObject.when pushing changes to a remote repository' {
    GivenRemoteRepository 'RemoteRepo'
    GivenLocalRepositoryTracksRemote 'LocalRepo'
    GivenCommittedChangeToPush
    WhenSendingObject 'refs/heads/master'
    ThenNoErrorsWereThrown
    ThenPushResultIs ([LibGit2.Automation.PushResult]::Ok)
    ThenRemoteContainsLocalCommits
}

Describe 'Send-GitObject.when there are no local changes to push to remote' {
    GivenRemoteRepository 'RemoteRepo'
    GivenLocalRepositoryTracksRemote 'LocalRepo'
    WhenSendingObject 'refs/heads/master'
    ThenNoErrorsWereThrown
    ThenPushResultIs ([LibGit2.Automation.PushResult]::Ok)
}

Describe 'Send-GitObject.when remote repository has changes not contained locally' {
    GivenRemoteRepository 'RemoteRepo'
    GivenLocalRepositoryTracksRemote 'LocalRepo'
    GivenRemoteContainsOtherChanges
    GivenCommittedChangeToPush
    WhenSendingObject 'refs/heads/master' -ErrorAction SilentlyContinue
    ThenErrorWasThrown 'that you are trying to update on the remote contains commits that are not present locally.'
    ThenPushResultIs ([LibGit2.Automation.PushResult]::Rejected)
}

Describe 'Send-GitObject.when no upstream remote is defined' {
    GivenLocalRepositoryWithNoRemote 'LocalRepo'
    GivenCommittedChangeToPush
    WhenSendingObject 'refs/heads/master' -ErrorAction SilentlyContinue
    ThenErrorWasThrown 'A\ remote\ named\ "origin"\ does\ not\ exist\.'
    ThenPushResultIs ([LibGit2.Automation.PushResult]::Failed)
}

Describe 'Send-GitObject.when refspec doesn''t exist' {
    GivenRemoteRepository 'RemoteRepo'
    GivenLocalRepositoryTracksRemote 'LocalRepo'
    WhenSendingObject 'refs/heads/dsfsdaf' -ErrorAction SilentlyContinue
    ThenErrorWasThrown 'does\ not\ match\ any\ existing\ object'
    ThenPushResultIs ([LibGit2.Automation.PushResult]::Failed)
}

Describe 'Send-GitObject.when pushing tags' {
    GivenRemoteRepository 'RemoteRepo'
    GivenLocalRepositoryTracksRemote 'LocalRepo'
    GivenTag 'tag1'
    WhenSendingObject 'refs/tags/tag1'
    ThenRemoteHasRevision 'tag1'
}