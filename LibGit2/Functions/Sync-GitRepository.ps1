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

function Sync-GitRepository
{
    <#
    .SYNOPSIS
    Synchronizes the current Git repository with its remote source repository.

    .DESCRIPTION
    The `Sync-GitRepository` function synchronizes all commits to the current branch of the local Git repository to its upstream remote repository. If the repository requires authentication, pass the username/password via the `Credential` parameter.

    This function implements the `git push` command.

    .EXAMPLE
    Sync-GitRepository

    Pushes commits from the repository at the current location to its upstream remote repository

    .EXAMPLE
    Sync-GitRepository -RepoRoot 'C:\Build\TestGitRepo' -Credential $PsCredential

    Pushes commits from the repository located at 'C:\Build\TestGitRepo' to its remote using authentication
    #>
    [CmdletBinding()]
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
    
    $currentBranch = $repo.Branches | Where-Object { $_.IsCurrentRepositoryHead -eq $true }
    if( !$currentBranch.Remote )
    {
        Write-Error -Message ('No upstream remote is configured for ''{0}'' branch. Aborting synchronization.' -f $currentBranch.Name)
        return
    }

    $pushOptions = New-Object 'LibGit2Sharp.PushOptions'
    if( $Credential )
    {
        $gitCredential = New-Object 'LibGit2Sharp.SecureUsernamePasswordCredentials'
        $gitCredential.Username = $Credential.UserName
        $gitCredential.Password = $Credential.Password
        $pushOptions.CredentialsProvider = { return $gitCredential }
    }

    try
    {
        $repo.Network.Push($currentBranch.Remote, $currentBranch, $pushOptions)
    }
    finally
    {
        $repo.Dispose()
    }
}
