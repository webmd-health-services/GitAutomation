
#Requires -Version '5.1'
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:testDirPath = $null
    $script:testNum = 0
    $script:output = $null

    function GivenLocalRepository
    {
        param(
            $Path
        )

        New-GitRepository -Path $Path
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

        $Global:Error.Count | Should -Be 0
        git -C $Destination status --porcelain 2>&1 | Should -BeNullOrEmpty
        $LASTEXITCODE | Should -Be 0

        if( $WithNoOutput )
        {
            $script:output | Should -BeNullOrEmpty
        }
        else
        {
            $script:output | Should -BeOfType ([IO.DirectoryInfo])
            $script:output.FullName | Should -Be (Join-Path -Path $Destination -ChildPath '.git\')
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
}

Describe 'Copy-GitRepository' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testDirPath -ItemType Directory
    }

    It 'cloning a remote repository' {
        $destination = Join-Path -Path $script:testDirPath -ChildPath 'repo'
        GivenThereAreNoErrors
        WhenCloningRepository 'https://github.com/webmd-health-services/GitAutomation' -To $destination
        ThenRepositoryWasClonedTo $destination -WithNoOutput
    }

    It 'cloning a repository with relative paths' {
        Push-Location -Path $script:testDirPath
        try
        {
            GivenLocalRepository 'fubar'
            GivenThereAreNoErrors
            WhenCloningRepository 'fubar' -To 'snafu'
            ThenRepositoryWasClonedTo (Join-Path -Path $script:testDirPath -ChildPath 'snafu') -WithNoOutput
        }
        finally
        {
            Pop-Location
        }
    }

    It 'cloning a repository with the -PassThru switch' {
        $sourcePath = Join-Path -Path $script:testDirPath -ChildPath 'fubar'
        $destinationPath = Join-Path -Path $script:testDirPath -ChildPath 'snafu'
        GivenLocalRepository $sourcePath
        GivenThereAreNoErrors
        WhenCloningRepository $sourcePath -To $destinationPath -PassThru
        ThenRepositoryWasClonedTo $destinationPath
    }
}
