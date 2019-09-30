
function Update-GitConfigurationSearchPath
{
    [CmdletBinding()]
    param(
        [LibGit2Sharp.ConfigurationLevel]
        # The scope of the configuration. Nothing is updated unless `Global` is used.
        $Scope
    )

    Set-StrictMode -Version 'Latest'

    if( $Scope -ne [LibGit2Sharp.ConfigurationLevel]::Global )
    {
        return
    }

    if( -not (Test-Path -Path 'env:HOME') )
    {
        return
    }

    $homePath = Get-Item -Path 'env:HOME' | Select-Object -ExpandProperty 'Value'
    $homePath = $homePath -replace '\\','/'

    [string[]]$searchPaths = [LibGit2Sharp.GlobalSettings]::GetConfigSearchPaths($Scope)
    if( $searchPaths[0] -eq $homePath )
    {
        return
    }

    $searchList = New-Object -TypeName 'Collections.Generic.List[string]' 
    $searchList.Add($homePath)
    $searchList.AddRange($searchPaths)

    [LibGit2Sharp.GlobalSettings]::SetConfigSearchPaths($Scope, $searchList.ToArray())
}