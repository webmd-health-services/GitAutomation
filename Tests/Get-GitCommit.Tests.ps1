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

$commitOutput = $null
$repoRoot = $null

function Init
{
    $Global:Error.Clear()
    $Script:commitOutput = $null
    $Script:repoRoot = $null
}

function GivenARepository
{
    $Script:repoRoot = Join-Path -Path $TestDrive.FullName -ChildPath 'repo'
    New-GitRepository -Path $repoRoot | Out-Null
}

function AddCommit
{
    param(
        [int]
        $NumberOfCommits = 1
    )
    
    1..$NumberOfCommits | ForEach-Object {
        $filePath = Join-Path -Path $repoRoot -ChildPath ([System.IO.Path]::GetRandomFileName())
        [Guid]::NewGuid() | Set-Content -Path $filePath -Force
        Add-GitItem -Path $filePath -RepoRoot $repoRoot | Out-Null
        Save-GitChange -Message 'Get-GitCommit Tests' -RepoRoot $repoRoot | Out-Null
    }
}

function WhenGettingCommit
{
    [CmdletBinding(DefaultParameterSetName='Default')]
    param(
        [Parameter(ParameterSetName='All')]
        [switch]
        $All,

        [Parameter(ParameterSetName='Lookup')]
        [string]
        $Revision
    )

    if ($PSCmdlet.ParameterSetName -eq 'All')
    {
        $Script:commitOutput = Get-GitCommit -RepoRoot $repoRoot -All
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Lookup')
    {
        $Script:commitOutput = Get-GitCommit -RepoRoot $repoRoot -Revision $Revision
    }
    else
    {
        Push-Location $repoRoot
        try
        {
            $Script:commitOutput = Get-GitCommit
        }
        finally
        {
            Pop-Location
        }
    }
}

function ThenCommitIsHeadCommit
{
    It 'should return the current HEAD commit' {
        $commitOutput.Sha | Should -Be (Get-Content -Path (Join-Path -Path $repoRoot -ChildPath '.git\refs\heads\master'))
    }
}

function ThenNumberCommitsReturnedIs
{
    param(
        [int]
        $NumberOfCommits
        )

        It 'should return the correct number of commits' {
            $commitOutput.Count | Should -Be $NumberOfCommits
        }
}

function ThenReturned
{
    param(
        [Parameter(Mandatory=$true,ParameterSetName='Type')]
        $Type,
        [Parameter(Mandatory=$true,ParameterSetName='Nothing')]
        [switch]
        $Nothing
        )

    if ($Nothing)
    {
        It 'should not return anything' {
            $commitOutput | Should -BeNullOrEmpty
        }
    }
    else
    {
        It 'should return the correct object type' {
            $commitOutput | Should -BeOfType $Type
        }
    }
}

function ThenErrorMessage
{
    param(
        $Message
    )

    It ('should write error /{0}/' -f $Message) {
        $Global:Error[0] | Should -Match $Message
    }
}

function ThenNoErrorMessages
{
    It 'should not write any errors' {
        $Global:Error | Should -BeNullOrEmpty
    }
}

Describe 'Get-GitCommit.when no parameters specified' {
    Init
    GivenARepository
    AddCommit -NumberOfCommits 2
    WhenGettingCommit
    ThenReturned -Type [LibGit2.Automation.CommitInfo]
    ThenNumberCommitsReturnedIs 2
    ThenNoErrorMessages
}

Describe 'Get-GitCommit.when getting all commits' {
    Init
    GivenARepository
    AddCommit -NumberOfCommits 5
    WhenGettingCommit -All
    ThenReturned -Type [LibGit2.Automation.CommitInfo]
    ThenNumberCommitsReturnedIs 5
    ThenNoErrorMessages
}

Describe 'Get-GitCommit.when getting specifically the current HEAD commit' {
    Init
    GivenARepository
    AddCommit -NumberOfCommits 3
    WhenGettingCommit -Revision 'HEAD'
    ThenReturned -Type [LibGit2.Automation.CommitInfo]
    ThenNumberCommitsReturnedIs 1
    ThenCommitIsHeadCommit
    ThenNoErrorMessages
}

Describe 'Get-GitCommit.when getting a commit that does not exist' {
    Init
    GivenARepository
    AddCommit -NumberOfCommits 1
    WhenGettingCommit -Revision 'nonexistentcommit' -ErrorAction SilentlyContinue
    ThenReturned -Nothing
    ThenErrorMessage 'Commit ''nonexistentcommit'' not found in repository'
}
