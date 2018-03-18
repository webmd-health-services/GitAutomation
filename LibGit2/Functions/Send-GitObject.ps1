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

function Send-GitObject
{
    <#
    .SYNOPSIS
    Sends Git refs and object to a remote repository.

    .DESCRIPTION
    The `Send-GitObject` functions sends objects from a local repository to a remote repository. You specify what refs and objects to send with the `Revision` parameter.

    This command implements the `git push` command.

    .EXAMPLE
    Send-GitObject -Revision master

    Demonstrates how to push the commits on a specific branch to the default remote repository.

    .EXAMPLE
    Send-GitObject -Revision 'refs/tags/*'

    Demonstrates how to push specific refs all tags to the default remote repository. To push a specific tag, you could also use the tag's name.

    .EXAMPLE
    Send-GitObject -Tags

    Demon
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The refs that should be pushed to the remote repository.
        $RefSpec,

        [string]
        # The name of the remote repository to send the changes to. The default is `origin`.
        $RemoteName = 'origin',

        [string]
        # The path to the local repository from which to push changes. Defaults to the current directory.
        $RepoRoot = (Get-Location).ProviderPath,
        
        [pscredential]
        # The credentials to use to connect to the source repository.
        $Credential
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    $repo = Find-GitRepository -Path $RepoRoot -Verify
    
    $pushOptions = New-Object -TypeName 'LibGit2Sharp.PushOptions'
    if( $Credential )
    {
        $gitCredential = New-Object -TypeName 'LibGit2Sharp.SecureUsernamePasswordCredentials'
        $gitCredential.Username = $Credential.UserName
        $gitCredential.Password = $Credential.Password
        $pushOptions.CredentialsProvider = { return $gitCredential }
    }

    $remote = $repo.Network.Remotes | Where-Object { $_.Name -eq $RemoteName }
    if( -not $remote )
    {
        Write-Error -Message ('A remote named "{0}" does not exist.' -f $RemoteName)
        return [LibGit2.Automation.PushResult]::Failed
    }

    try
    {
        $repo.Network.Push($remote, $RefSpec, $pushOptions)
        return [LibGit2.Automation.PushResult]::Ok
    }
    catch
    {
        Write-Error -ErrorRecord $_
        
        switch ( $_.FullyQualifiedErrorId )
        {
            'NonFastForwardException' { return [LibGit2.Automation.PushResult]::Rejected }
            'LibGit2SharpException' { return [LibGit2.Automation.PushResult]::Failed }
            'BareRepositoryException' { return [LibGit2.Automation.PushResult]::Failed }
            default { return [LibGit2.Automation.PushResult]::Failed }
        }
    }
    finally
    {
        $repo.Dispose()
    }

}
