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

$remoteRepoRoot = $null
$remoteWorkingRoot = $null
$localRoot = $null

function Init
{
    param(
    )
    
    $script:remoteRepoRoot = Join-Path -Path $TestDrive -ChildPath 'Remote.Bare'
    New-GitRepository -Path $remoteRepoRoot -Bare

    $script:remoteWorkingRoot = Join-Path -Path $TestDrive.FullName -ChildPath 'Remote.Working'
    Copy-GitRepository -Source $remoteRepoRoot -DestinationPath $remoteWorkingRoot

    Add-GitTestFile -RepoRoot $remoteWorkingRoot -Path 'InitialCommit.txt'
    Add-GitItem -RepoRoot $remoteWorkingRoot -Path 'InitialCommit.txt'
    Save-GitChange -RepoRoot $remoteWorkingRoot -Message 'Initial Commit'
    Send-GitCommit -RepoRoot $remoteWorkingRoot

}

function GivenLocalRepoIs
{
    param(
        [Switch]
        $ClonedFromRemote,

        [Switch]
        $Standalone
    )
    
    $script:localRoot = Join-Path -Path $TestDrive -ChildPath ('Local.{0}' -f [IO.Path]::GetRandomFileName())
    if( $ClonedFromRemote )
    {
        Copy-GitRepository -Source $remoteRepoRoot -DestinationPath $localRoot
    }
    else
    {
        New-GitRepository -Path $localRoot
    }
}

function GivenCommit
{
    param(
        [Switch]
        $InRemote,

        [Switch]
        $InLocal
    )
    
    if( $InRemote )
    {
        $repoRoot = $remoteWorkingRoot
        $prefix = 'remote'
    }
    else
    {
        $repoRoot = $localRoot
        $prefix = 'local'
    }
        
    $filename = '{0}-{1}' -f $prefix,[IO.Path]::GetRandomFileName()
    Add-GitTestFile -RepoRoot $repoRoot -Path $filename | Out-Null
    Add-GitItem -RepoRoot $repoRoot -Path $filename
    Save-GitChange -RepoRoot $repoRoot -Message $filename

    if( $InRemote )
    {
        Send-GitCommit -RepoRoot $remoteWorkingRoot | Out-Null
    }
}

function WhenSendingCommits
{
    [CmdletBinding()]
    param(
    )

    $Global:Error.Clear()
    $script:pushResult = $null
    
    $script:pushResult = Send-GitCommit -RepoRoot $localRoot #-ErrorAction SilentlyContinue
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

function ThenRemoteContains
{
    param(
        [string]
        $Revision
    )

    It ('should push branch to remote') {
        Test-GitCommit -RepoRoot $remoteRepoRoot -Revision $Revision | Should -BeTrue
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

Describe 'Send-GitCommit.when pushing changes to a remote repository' {
    Init
    GivenLocalRepoIs -ClonedFromRemote
    $commit = GivenCommit -InLocal
    WhenSendingCommits
    ThenNoErrorsWereThrown
    ThenPushResultIs ([LibGit2.Automation.PushResult]::Ok)
    ThenRemoteContains $commit.Sha
}

Describe 'Send-GitCommit.when there are no local changes to push to remote' {
    Init
    GivenLocalRepoIs -ClonedFromRemote
    WhenSendingCommits
    ThenNoErrorsWereThrown
    ThenPushResultIs ([LibGit2.Automation.PushResult]::Ok)
}

Describe 'Send-GitCommit.when remote repository has changes not contained locally' {
    Init
    GivenLocalRepoIs -ClonedFromRemote
    GivenCommit -InRemote
    GivenCommit -InLocal
    WhenSendingCommits -ErrorAction SilentlyContinue
    ThenErrorWasThrown 'that you are trying to update on the remote contains commits that are not present locally.'
    ThenPushResultIs ([LibGit2.Automation.PushResult]::Rejected)
}

Describe 'Send-GitCommit.when no upstream remote is defined' {
    Init
    GivenLocalRepoIs -Standalone
    GivenCommit -InLocal
    WhenSendingCommits -ErrorAction SilentlyContinue
    ThenErrorWasThrown 'A\ remote\ named\ "origin"\ does\ not\ exist\.'
    ThenPushResultIs ([LibGit2.Automation.PushResult]::Failed)
}

