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
    
function Get-GitCommit
{
    <#
    .SYNOPSIS
    Gets the sha-1 ID for specific changes in a Git repository.

    .DESCRIPTION
    The `Get-GitCommit` gets all the commits in a repository, from most recent to oldest.

    To get a commit for a specific named revision, e.g. HEAD, a branch, a tag), pass the name to the `Revision` parameter.

    To get the commit of the current checkout, pass `HEAD` to the `Revision` parameter.
    #>
    [CmdletBinding(DefaultParameterSetName='All')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='Lookup')]
        [string]
        # A named revision to get, e.g. `HEAD`, a branch name, tag name, etc.
        #
        # To get the commit of the current checkout, pass `HEAD`.
        $Revision,

        [string]
        # The path to the repository. Defaults to the current directory.
        $RepoRoot
    )

    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot
    if( -not $repo )
    {
        return
    }
    
    try
    {
        if( $PSCmdlet.ParameterSetName -eq 'All' )
        {
            $repo.Commits | ForEach-Object { New-Object -TypeName 'LibGit2.Automation.CommitInfo' -ArgumentList $_ }
            return
        }

        $change = $repo.Lookup($Revision)
        if( $change )
        {
            return New-Object -TypeName 'LibGit2.Automation.CommitInfo' -ArgumentList $change
        }
        else
        {
            Write-Error -Message ('Commit ''{0}'' not found in repository ''{1}''.' -f $Revision,$repo.Info.WorkingDirectory) -ErrorAction $ErrorActionPreference
        }
    }
    finally
    {
        $repo.Dispose()
    }

}
