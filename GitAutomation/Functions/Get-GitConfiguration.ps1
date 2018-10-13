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
    [CmdletBinding()]
    [OutputType([LibGit2Sharp.ConfigurationEntry[string]])]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        # The name of the configuration variable to get.
        $Name,

        [Parameter(ParameterSetName='ByScope')]
        [LibGit2Sharp.ConfigurationLevel]
        # Where to get the configuration value. By default, all levels of configuration are searched. Local means the value will be gotten from the config file in the repository of the current working directory (or the repository at `RepoRoot` if passing the path to a specific repository to that parameter). Global means from the current user's config file. System means from the config file in Git's installation directory. The default is `Local`.
        $Scope = [LibGit2Sharp.ConfigurationLevel]::Local,

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
            $value = [Git.Automation.ConfigurationExtensions]::GetString( $config, $Name )
        }
        finally
        {
            $config.Dispose()
        }    
    }

    return $value
}
