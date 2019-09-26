[CmdletBinding(DefaultParameterSetName='Build')]
param(
    [Parameter(Mandatory,ParameterSetName='Clean')]
    # Runs the build in clean mode, which removes any files, tools, packages created by previous builds.
    [Switch]$Clean,

    [Parameter(Mandatory,ParameterSetName='Initialize')]
    # Initializes the repository.
    [Switch]$Initialize
)

#Requires -Version 5.1
Set-StrictMode -Version Latest

# Set to a specific version to use a specific version of Whiskey. 
$whiskeyVersion = '0.*'
$allowPrerelease = $true

$psModulesRoot = Join-Path -Path $PSScriptRoot -ChildPath 'PSModules'
$whiskeyModuleRoot = Join-Path -Path $PSScriptRoot -ChildPath 'PSModules\Whiskey'

if( -not (Test-Path -Path $whiskeyModuleRoot -PathType Container) )
{
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    $release = 
        Invoke-RestMethod -Uri 'https://api.github.com/repos/webmd-health-services/Whiskey/releases' |
        ForEach-Object { $_ } |
        Where-Object { $_.name -like $whiskeyVersion } |
        Where-Object {
            if( $allowPrerelease )
            {
                return $true
            }
            [version]::TryParse($_.name,[ref]$null)
            return $true
        } |
        Sort-Object -Property 'created_at' -Descending |
        Select-Object -First 1

    if( -not $release )
    {
        Write-Error -Message ('Whiskey version "{0}" not found.' -f $whiskeyVersion) -ErrorAction Stop
        return
    }

    $zipUri = 
        $release.assets |
        ForEach-Object { $_ } |
        Where-Object { $_.name -eq 'Whiskey.zip' } |
        Select-Object -ExpandProperty 'browser_download_url'
    
    if( -not $zipUri )
    {
        Write-Error -Message ('URI to Whiskey ZIP file does not exist.') -ErrorAction Stop
    }

    Write-Verbose -Message ('Found Whiskey {0}.' -f $release.name)

    if( -not (Test-Path -Path $psModulesRoot -PathType Container) )
    {
        New-Item -Path $psModulesRoot -ItemType 'Directory' | Out-Null
    }
    $zipFilePath = Join-Path -Path $psModulesRoot -ChildPath 'Whiskey.zip'
    & {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -UseBasicParsing -Uri $zipUri -OutFile $zipFilePath
    }

    # Whiskey.zip uses Windows directory separator which extracts strangely on Linux. So, we have
    # to extract each entry by hand.
    Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
    $zipFile = [IO.Compression.ZipFile]::OpenRead($zipFilePath)
    try
    {
        foreach( $entry in $zipFile.Entries )
        {
            $destinationPath = Join-Path -Path $whiskeyModuleRoot -ChildPath $entry.FullName
            $destinationDirectory = $destinationPath | Split-Path
            if( -not (Test-Path -Path $destinationDirectory -PathType Container) )
            {
                New-Item -Path $destinationDirectory -ItemType 'Directory' | Out-Null
            }
            Write-Debug -Message ('{0} -> {1}' -f $entry.FullName,$destinationPath)
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destinationPath, $true)
        }
    }
    finally
    {
        $zipFile.Dispose()
    }

    # Remove any prerelease information.
    $moduleDirName = $release.name -replace '-.*$',''
    Rename-Item -Path (Join-Path -Path $whiskeyModuleRoot -ChildPath 'Whiskey') -NewName $moduleDirName

    Remove-Item -Path $zipFilePath
}

& {
    $VerbosePreference = 'SilentlyContinue'
    Import-Module -Name $whiskeyModuleRoot -Force
}

$optionalArgs = @{ }
if( $Clean )
{
    $optionalArgs['Clean'] = $true
}

if( $Initialize )
{
    $optionalArgs['Initialize'] = $true
}

$configPath = Join-Path -Path $PSScriptRoot -ChildPath 'whiskey.yml' -Resolve

$context = New-WhiskeyContext -Environment 'Dev' -ConfigurationPath $configPath
if( (Test-Path -Path 'env:GITHUB_ACCESS_TOKEN') )
{
    Add-WhiskeyApiKey -Context $context -ID 'github.com' -Value $env:GITHUB_ACCESS_TOKEN
}
if( (Test-Path -Path 'env:POWERSHELLGALLERY_COM_API_KEY') )
{
    Add-WhiskeyApiKey -Context $context -ID 'powershellgallery.com' -Value $env:POWERSHELLGALLERY_COM_API_KEY
}
Invoke-WhiskeyBuild -Context $context @optionalArgs
