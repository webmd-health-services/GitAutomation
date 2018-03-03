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

function Save-GitChange
{
    <#
    .SYNOPSIS
    Commits changes to a Git repository.

    .DESCRIPTION
    The `Save-GitChange` function commits changes to a Git repository. Those changes must be staged first with `git add` or the `LibGit2` module's `Add-GitItem` function. If there are no changes staged, nothing happens and you'll see a warning.

    You are required to pass a commit message with the `Message` parameter. This module is intended to be used by non-interactive repository automation scripts, so opening in an editor is not supported.

    Implements the `git commit` command.

    .OUTPUTS
    LibGit2.Automation.CommitInfo

    .LINK
    Add-GitItem

    .EXAMPLE
    Save-GitChange -Message 'Creating Save-GitChange function.'

    Demonstrates how to commit staged changes in a Git repository. In this example, the repository is assumed to be in the current directory.

    .EXAMPLE
    Save-GitChange -Message 'Creating Save-GitChange function.' -RepoRoot 'C:\Projects\LibGit2.PowerShell'

    Demonstrates how to commit changes to a repository other than the current directory.
    #>
    [CmdletBinding()]
    [OutputType([LibGit2.Automation.CommitInfo])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The commit message.
        $Message,

        [string]
        # The repository where to commit staged changes. Defaults to the current directory.
        $RepoRoot,

        [LibGit2Sharp.Signature]
        # Author metadata. If not provided, it is pulled from configuration. To create an author/signature object, 
        #
        #     New-Object -TypeName 'LibGit2Sharp.Signature' -ArgumentList 'NAME','email@example.com',(Get-Date)
        #
        $Signature
    )

    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if( -not $repo )
    {
        return
    }

    try
    {
        $commitOptions = New-Object 'LibGit2Sharp.CommitOptions'
        $commitOptions.AllowEmptyCommit = $false
        if( -not $Signature )
        {
            $Signature = $repo.Config.BuildSignature((Get-Date))
            if( -not $Signature )
            {
                Write-Error -Message ('Failed to build commit author signature from Git configuration files. Please pass a custom author signature to the "Signature" parameter or set them for the current user by running these commands:
 
    git config --global user.name "GIVEN_NAME SURNAME"
    git config --global user.email "email@example.com"
 ')
                return
            }
        }
        $repo.Commit( $Message, $Signature, $Signature, $commitOptions ) |
            ForEach-Object { New-Object 'LibGit2.Automation.CommitInfo' $_ } 
    }
    catch [LibGit2Sharp.EmptyCommitException]
    {
        Write-Warning -Message ('Nothing to commit. Git only commits changes that are staged. To stage changes, use the Add-GitItem function or the `git add` command.')
    }
    catch 
    {
        Write-Error -ErrorRecord $_
    }
    finally
    {
        $repo.Dispose()
    }

}