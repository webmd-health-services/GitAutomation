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

function New-GitRepository
{
    <#
    .SYNOPSIS
    Creates a new Git repository.

    .DESCRIPTION
    The `New-GitRepository` function creates a new Git repository. The `Path` parameter should be set to a directory path. If the path does not exist, it is created and that directory becomes the new repository's root. If the path does exist, it also becomes the root of a new repository. If the path exists and it is already a repository, nothing happens.

    .OUTPUTS
    LibGit2.Automation.RepositoryInfo.

    .EXAMPLE
    New-GitRepository -Path 'C:\Projects\MyCoolNewRepo'

    Demonstrates how to create a new Git repository. In this case, a new repository is created in `C:\Projects\MyCoolNewRepo'.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([LibGit2.Automation.RepositoryInfo])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the repository to create.
        $Path
    )

    Set-StrictMode -Version 'Latest'

    if( -not [IO.Path]::IsPathRooted($Path) )
    {
        $Path = Join-Path -Path (Get-Location).ProviderPath -ChildPath $Path
        $Path = [IO.Path]::GetFullPath($Path)
    }

    $whatIfMessage = 'create Git repository at ''{0}''' -f $Path
    if( -not $PSCmdlet.ShouldProcess($whatIfMessage, $whatIfMessage, 'New-GitRepository' ) )
    {
        return
    }

    $repoPath = [LibGit2Sharp.Repository]::Init($Path)
    $repo = New-Object 'LibGit2Sharp.Repository' $repoPath
    try
    {
        return New-Object 'LibGit2.Automation.RepositoryInfo' $repo.Info
    }
    finally
    {
        $repo.Dispose()
    }
}