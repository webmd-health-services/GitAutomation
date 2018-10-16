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

function Remove-GitConfiguration
{
    <#
    .SYNOPSIS
    Removes/unsets a Git configuration value.

    .DESCRIPTION
    The `Remove-GitConfiguration` function removes/unsets a Git configuration value. Pass the name of the setting to the `Name` parameter (sections and names should be seperated by a dot, e.g. `user.name`). Pass the scope at which you want the configuration removed to the `Scope` parameter. Values are:

    * `Local`: the setting will be removed from the repository in the current working directory's `.git\config` file.
    * `Global`: the setting will be removed from the user's `.gitconfig` file.
    * `Xdg`: the setting will be removed from the user's `.config\git\config` file.
    * `System`: the setting will be removed from Git's global `gitconfig` file.
    * `ProgramData` the setting will be removed from the `Git\config` file in Windows' `ProgramData` directory.

    To work on a specific repository, pass its path to the `RepoRoot` directory.

    To operate on a specific file, pass its path to the `Path` directory.

    If the setting doesn't exist, nothing happens.

    .EXAMPLE
    Remove-GitConfiguration -Name 'user.name' -Scope Global

    Demonstrates how to removes a setting from a given scope. In this case, the `user.name` setting will be removed from the user's `.gitconfig` file.

    .EXAMPLE
    Remove-GitConfiguration -Name 'user.name' -Scope Local -RepoRoot 'C:\Projects\GitAutomation'

    Demonstrates how to remove a setting from a specific repository. In this case, the `user.name` setting is removed from the `.git\config` file in the `C:\Projects\GitAutomation` repository.


    .EXAMPLE
    Remove-GitConfiguration -Name 'user.name' -Path 'C:\Projects\GitAutomation\template.gitconfig'

    Demonstrates how to remove a setting from a specific file. In this case, the `user.name` setting is removed from the `C:\Projects\GitAutomation\template.gitconfig` file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        # The name of the configuration variable to set.
        $Name,

        [Parameter(ParameterSetName='ByScope')]
        [LibGit2Sharp.ConfigurationLevel]
        # Where to set the configuration value. Local means the value will be set for a specific repository. Global means set for the current user. System means set for all users on the current computer. The default is `Local`.
        $Scope = ([LibGit2Sharp.ConfigurationLevel]::Local),

        [Parameter(Mandatory=$true,ParameterSetName='ByPath')]
        [string]
        # The path to a specific file whose configuration to update.
        $Path,

        [Parameter(ParameterSetName='ByScope')]
        [string]
        # The path to the repository whose configuration variables to set. Defaults to the repository the current directory is in.
        $RepoRoot = (Get-Location).Path
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'ByPath' )
    {
        if( -not (Test-Path -Path $Path -PathType Leaf) )
        {
            return
        }

        $Path = Resolve-Path -Path $Path | Select-Object -ExpandProperty 'ProviderPath'

        $config = [LibGit2Sharp.Configuration]::BuildFrom($Path)
        try
        {
            $config.Unset( $Name, [LibGit2Sharp.ConfigurationLevel]::Local )
        }
        finally
        {
            $config.Dispose()
        }
        return
    }

    $pathParam = @{}
    if( $RepoRoot )
    {
        $pathParam['Path'] = $RepoRoot
    }

    if( $Scope -eq [LibGit2Sharp.ConfigurationLevel]::Local )
    {
        $repo = Find-GitRepository @pathParam -Verify -ErrorAction Ignore
        if( -not $repo )
        {
            Write-Error -Message ('There is no Git repository at "{0}". Unable to unset "{1}".' -f $RepoRoot,$Name)
            return
        }

        try
        {
            $repo.Config.Unset($Name,$Scope)
        }
        finally
        {
            $repo.Dispose()
        }
        return
    }

    $config = [LibGit2Sharp.Configuration]::BuildFrom([nullstring]::Value,[nullstring]::Value)
    try
    {
        $config.Unset($Name,$Scope)
    }
    finally
    {
        $config.Dispose()
    }

}