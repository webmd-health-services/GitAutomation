
function ConvertTo-GitFullPath
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='Path')]
        [string]
        # A path to convert to a full path.
        $Path,

        [Parameter(Mandatory=$true,ParameterSetName='Uri')]
        [uri]
        # A URI to convert to a full path. It can be a local path.
        $Uri
    )

    Set-StrictMode -Version 'Latest'

    if( $PSCmdlet.ParameterSetName -eq 'Uri' )
    {
        if( $Uri.Scheme )
        {
            return $Uri.ToString()
        }

        $Path = $Uri.ToString()
    }

    if( [IO.Path]::IsPathRooted($Path) )
    {
        return $Path
    }

    $Path = Join-Path -Path (Get-Location) -ChildPath $Path
    [IO.Path]::GetFullPath($Path)
}