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

function Send-GitCommit
{
    <#
    .SYNOPSIS
    Pushes commits from the current Git repository to its remote source repository.

    .DESCRIPTION
    The `Send-GitCommit` function sends all commits on the current branch of the local Git repository to its upstream remote repository. If the repository requires authentication, pass the username/password via the `Credential` parameter.

    This function implements the `git push` command. A return value of $true indicates commits were successfully pushed to the remote. Otherwise, a warning or error message will be returned.

    .EXAMPLE
    Send-GitCommit

    Pushes commits from the repository at the current location to its upstream remote repository

    .EXAMPLE
    Send-GitCommit -RepoRoot 'C:\Build\TestGitRepo' -Credential $PsCredential

    Pushes commits from the repository located at 'C:\Build\TestGitRepo' to its remote using authentication
    #>
    [CmdletBinding()]
    [OutputType([LibGit2.Automation.PushResult])]
    param(
        [string]
        # Specifies the location of the repository to synchronize. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,
        
        [pscredential]
        # The credentials to use to connect to the source repository.
        $Credential
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    
    try
    {
        [LibGit2Sharp.Branch]$currentBranch = $repo.Branches | Where-Object { $_.IsCurrentRepositoryHead -eq $true }
        if( -not (Test-GitOutgoingCommit -RepoRoot $RepoRoot) )
        {
            return [LibGit2.Automation.PushResult]::Ok
        }

        Send-GitObject -RefSpec $currentBranch.CanonicalName -RepoRoot $RepoRoot -Credential $Credential
    }
    finally
    {
        $repo.Dispose()
    }
}
