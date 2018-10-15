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

function Get-GitConfiguration
{
    <#
    .SYNOPSIS
    Gets Git configuration.

    .DESCRIPTION
    The `Get-GitConfiguration` function returns Git's configuration as `LibGit2Sharp.ConfigurationEntry` objects. When run outside a repository, it gets configuration from the user's and system's configuration files. When run from inside a repository, it also returns that repository's settings. The objects returned have the following properties:

    * `Key`: the key/name of the setting. This will be the section and name seperated by a dot, e.g. `user.name`.
    * `Value`: the setting's value.
    * `Level`: a `LibGit2Sharp.ConfigurationLevel` enumeration value indicating at what level/scope the setting is defined. `Local` means its set in a repository's `.git\config` file. `Global` means its set in the user's `.gitconfig` file. `Xdg` means it set in the user's `.config\git\config` file. `System` means its set in the global `gitconfig` file. `ProgramData` means it is defined in Git's system-wide `Git\config` file in Windows' `ProgramData` directory.

    You can explicitly set the repository whose settings to get with the `RepoRoot` parameter. Settings at higher levels will also be returned.

    You can read configuration from a specific file by passing the file's path to the `Path` parameter. When reading from a specific file, settings at higher levels (e.g. global and system) are also returned.

    To return a specific configuration setting, pass its name to the `Name` parameter. If a setting with that name doesn't exist, nothing is returned. Sections and setting names should be seperated by periods, e.g. `user.name`.

    .EXAMPLE
    Get-GitConfiguration

    Demonstrates how to get all Git configuration.

    .EXAMPLE
    Get-GitConfiguration -Path 'template.gitconfig'

    Demonstrates how to read configuration from a specific git config file. Settings at higher levels (global/user and system) are still returned.

    .EXAMPLE 
    Get-GitConfiguration -Path 'template.gitconfig' | Where-Object { $_.Level -eq [LibGit2Sharp.ConfigurationLevel]::Local }

    Demonstrates how to read configuration from a specific git config file and filter out all settings that didn't come from that file.

    .EXAMPLE
    Get-GitConfiguration -Name 'user.email' 

    Demonstrates how to get a specific setting.
    #>
    [CmdletBinding(DefaultParameterSetName='ByScope')]
    [OutputType([LibGit2Sharp.ConfigurationEntry[string]])]
    param(
        [Parameter(Position=0)]
        [string]
        # The name of the configuration variable to get. By default all configuration settings are returned. The name should be the section and name seperated by a dot, e.g. `user.name`.
        $Name,

        [Parameter(Mandatory=$true,ParameterSetName='ByPath')]
        [string]
        # The path to a specific file from which to read configuration. If this file doesn't exist, it is created.
        $Path,

        [Parameter(ParameterSetName='ByScope')]
        [string]
        # The path to the repository whose configuration variables to set. Defaults to the repository the current directory is in.
        $RepoRoot
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'ByPath' )
    {
        if( -not (Test-Path -Path $Path -PathType Leaf) )
        {
            New-Item -Path $Path -ItemType 'File' -Force | Write-Verbose
        }

        $Path = Resolve-Path -Path $Path | Select-Object -ExpandProperty 'ProviderPath'

        $config = [LibGit2Sharp.Configuration]::BuildFrom($Path)
        try
        {
            if( -not $Name )
            {
                return $config
            }

            [Git.Automation.ConfigurationExtensions]::GetString( $config, $Name, 'Local' )
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
    
    $value = $null
        
    $repo = Find-GitRepository @pathParam -Verify -ErrorAction Ignore
    if( $repo )
    {
        try
        {
            if( -not $Name )
            {
                return $repo.Config
            }

            $value = [Git.Automation.ConfigurationExtensions]::GetString( $repo.Config, $Name )
        }
        finally
        {
            $repo.Dispose()
        }
    }
    
    if( -not $value )
    {
        $config = [LibGit2Sharp.Configuration]::BuildFrom([nullstring]::Value,[nullstring]::Value)
        try
        {
            if( -not $Name )
            {
                return $config
            }

            $value = [Git.Automation.ConfigurationExtensions]::GetString( $config, $Name )
        }
        finally
        {
            $config.Dispose()
        }    
    }

    return $value
}
