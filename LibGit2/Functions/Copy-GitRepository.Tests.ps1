
Set-StrictMode -Version 'Latest'

$PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition
& (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-LibGit2.ps1' -Resolve)

$output = $null

function GivenLocalRepository
{
    param(
        $Path
    )

    git init $Path
}

function GivenThereAreNoErrors
{
    $Global:Error.Clear()
}

function ThenRepositoryWasClonedTo
{
    param(
        $Destination,

        [Switch]
        $WithNoOutput
    )

    It 'should succeed' {
        $Global:Error.Count | Should Be 0
    }
    It 'should clone the repository' {
        git -C $Destination status --porcelain 2>&1 | Should BeNullOrEmpty
        $LASTEXITCODE | Should Be 0
    }

    if( $WithNoOutput )
    {
        It 'should return no output' {
            $output | Should BeNullOrEmpty
        }
    }
    else
    {
        It 'should return [IO.DirectoryInfo] for repository' {
            $output | Should BeOfType ([IO.DirectoryInfo])
            $output.FullName | Should Be (Join-Path -Path $Destination -ChildPath '.git\')
        }
    }
}

function WhenCloningRepository
{
    param(
        $Source,
        $To,
        [Switch]
        $PassThru
    )

    $script:output = Copy-GitRepository -Source $Source -DestinationPath $To -PassThru:$PassThru
}

Describe 'Copy-GitRepository when cloning a remote repository' {
    $destination = Join-Path -Path (Get-Item -Path 'TestDrive:').FullName -ChildPath 'LibGit2.PowerShell'
    GivenThereAreNoErrors
    WhenCloningRepository 'https://github.com/splatteredbits/LibGit2.PowerShell' -To $destination
    ThenRepositoryWasClonedTo $destination -WithNoOutput
}

Describe 'Copy-GitRepository when cloning a repository with relative paths' {
    Push-Location -Path (Get-Item -Path 'TestDrive:').FullName
    try
    {
        GivenLocalRepository 'fubar'
        GivenThereAreNoErrors
        WhenCloningRepository 'fubar' -To 'snafu'
        ThenRepositoryWasClonedTo (Join-Path -Path (Get-Item 'TestDrive:').FullName -ChildPath 'snafu') -WithNoOutput
    }
    finally
    {
        Pop-Location
    }
}

Describe 'Copy-GitRepository when cloning a repository with the -PassThru switch' {
    $tempRoot = Get-Item -Path 'TestDrive:'
    $tempRoot = $tempRoot.FullName
    $destinationPath = Join-Path -Path $tempRoot -ChildPath 'snafu'
    GivenLocalRepository 'fubar'
    GivenThereAreNoErrors
    WhenCloningRepository 'fubar' -To $destinationPath -PassThru
    ThenRepositoryWasClonedTo $destinationPath
}
