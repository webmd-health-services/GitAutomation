
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:repoDirPath = $null
    $script:repoNum = 0
    $script:name = $null
    $script:email = $null
    $script:when = $null

    function GivenRepositoryConfig
    {
        param(
            $Config
        )

        $script:repoDirPath = Join-Path -Path $TestDrive -ChildPath ($script:repoNum++)
        New-GitRepository -Path $script:repoDirPath
        $Config | Set-Content -Path (Join-Path -Path $script:repoDirPath -ChildPath '.git\config')
    }

    function Init
    {
        $script:name = $null
        $script:email = $null
        $script:when = $null
    }

    function ThenSignatureIs
    {
        param(
            $Name,
            $Email
        )

        $signature.Name | Should -Be $Name
        $signature.Email | Should -Be $Email
        $signature.When | Should -BeGreaterOrEqual $script:when
    }

    function WhenCreatingSignature
    {
        [CmdletBinding()]
        param(
            $Name,
            $Email,
            $RepoRoot
        )

        $parameters = @{ }
        if( $Name )
        {
            $parameters['Name'] = $Name
        }

        if( $Email )
        {
            $parameters['Email'] = $Email
        }

        if( $RepoRoot )
        {
            $parameters['RepoRoot'] = $RepoRoot
        }

        $script:when = [DateTimeOffset]::Now
        $Global:Error.Clear()
        $script:signature = New-GitSignature @parameters
    }
}

Describe 'New-GitSignature' {
    It 'passing author information' {
        WhenCreatingSignature 'Fubar Snafu' 'fizzbuzz@example.com'
        ThenSignatureIs 'Fubar Snafu' 'fizzbuzz@example.com'
    }

    It 'reading configuration from global files' {
        $blankGitConfigPath = Join-Path -Path $PSScriptRoot -ChildPath '..\GitAutomation\gitconfig'
        $config = [LibGit2Sharp.Configuration]::BuildFrom($blankGitConfigPath)
        $script:name = $config | Where-Object { $_.Key -eq 'user.name' } | Select-Object -ExpandProperty 'Value'
        $clearName = $false
        if( -not $script:name )
        {
            $script:name = 'name name'
            $config.Set('user.name',$script:name,[LibGit2Sharp.ConfigurationLevel]::Global)
            $clearName = $true
        }
        $script:email = $config | Where-Object { $_.Key -eq 'user.email' } | Select-Object -ExpandProperty 'Value'
        $clearEmail = $false
        if( -not $script:email )
        {
            $script:email = 'email@example.com'
            $config.Set('user.email',$script:email,[LibGit2Sharp.ConfigurationLevel]::Global)
            $clearEmail = $true
        }

        try
        {
            WhenCreatingSignature
            ThenSignatureIs $script:name $script:email
        }
        finally
        {
            if( $clearName )
            {
                $config.Unset('user.name',[LibGit2Sharp.ConfigurationLevel]::Global)
            }
            if( $clearEmail )
            {
                $config.Unset('user.email',[LibGit2Sharp.ConfigurationLevel]::Global)
            }
            $config.Dispose()
        }
    }

    It 'reading configuration from repository' {
        GivenRepositoryConfig '
    [user]
        name = Repo Repo
        email = repo@example.com
        '
        WhenCreatingSignature -RepoRoot $script:repoDirPath
        ThenSignatureIs 'Repo Repo' 'repo@example.com'
    }

    It 'configuration is missing' {
        $blankGitConfigPath = Join-Path -Path $PSScriptRoot -ChildPath '..\GitAutomation\gitconfig'
        $config = [LibGit2Sharp.Configuration]::BuildFrom($blankGitConfigPath)
        $script:name = $config | Where-Object { $_.Key -eq 'user.name' } | Select-Object -ExpandProperty 'Value'
        $script:email = $config | Where-Object { $_.Key -eq 'user.email' } | Select-Object -ExpandProperty 'Value'

        $config.Unset('user.name','Global')
        $config.Unset('user.email','Global')

        try
        {
            WhenCreatingSignature -ErrorAction SilentlyContinue
            $script:signature | Should -BeNullOrEmpty

            $Global:Error |  Should -Match 'Failed\ to\ build\ author\ signature'

            WhenCreatingSignature -ErrorAction Ignore
            $Global:Error.Count | Should -Be 0

        }
        finally
        {
            if( $script:name )
            {
                $config.Set('user.name',$script:name,'Global')
            }
            if( $script:email )
            {
                $config.Set('user.email',$script:email,'Global')
            }
            $config.Dispose()
        }
    }
}