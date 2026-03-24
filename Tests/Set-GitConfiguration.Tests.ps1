
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-GitAutomationTest.ps1' -Resolve)

    $script:testDirPath = $null
    $script:testNum = 0
    $script:repoNum = 0

    $script:globalSearchPaths = [LibGit2Sharp.GlobalSettings]::GetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global)

    function Assert-ConfigurationVariableSet
    {
        param(
            $Path
        )

        Get-Content -Path $Path | Where-Object { $_ -match 'autocrlf\ =\ false' } | Should -Not -BeNullOrEmpty
    }

    function GivenRepo
    {
        $repoRoot = Join-Path -Path $script:testDirPath -ChildPath ($script:repoNum++)
        New-GitRepository -Path $repoRoot | Format-List | Out-String | Write-Debug
        return $repoRoot
    }
}

AfterAll {
    [LibGit2Sharp.GlobalSettings]::SetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global, $script:globalSearchPaths)
}

Describe 'Set-GitConfiguration' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath ($script:testNum++)
        New-Item -Path $script:testDirPath -ItemType Directory
    }

    It 'setting the current repository''s configuration' {
        $repo = GivenRepo
        Push-Location -Path $repo
        try
        {
            Set-GitConfiguration -Name 'core.autocrlf' -Value 'false'
            Assert-ConfigurationVariableSet -Path '.git\config'
        }
        finally
        {
            Pop-Location
        }
    }

    It 'setting a specific repository''s configuration' {
        $repo = GivenRepo

        Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -RepoRoot $repo
        Assert-ConfigurationVariableSet -Path (Join-Path -Path $repo -ChildPath '.git\config')
    }

    It 'repo does not exist' {
        Set-GitConfiguration -Name 'core.autocrlf' `
                             -Value 'false' `
                             -RepoRoot (Get-Item -Path 'TestDrive:').FullName `
                             -ErrorVariable 'errors' `
                             -ErrorAction SilentlyContinue
        $errors | Should -Match 'not in a Git repository'
    }

    It 'setting global configuration' {
        $value = [Guid]::NewGuid()
        Set-GitConfiguration -Name 'GitAutomation.test' -Value $value -Scope Global
        $repo = Find-GitRepository -Path $PSScriptRoot
        $option =
            $repo.Config |
            Where-Object { $_.Key -eq 'GitAutomation.test' -and $_.Value -eq $value -and $_.Level -eq [LibGit2Sharp.ConfigurationLevel]::Global } |
            Should -Not -BeNullOrEmpty
    }

    It 'setting a specific repository''s configuration and current directory is a sub-directory of the repository root' {
        $repo = GivenRepo
        Push-Location -Path $repo
        try
        {
            New-Item -Path 'child' -ItemType 'Directory'
            Set-Location -Path 'child'

            Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -ErrorVariable 'errors'
            Assert-ConfigurationVariableSet -Path '..\.git\config'
            $errors | Should -BeNullOrEmpty
        }
        finally
        {
            Pop-Location
        }
    }
    It 'using a specific configuration file' {
        $file = Join-Path -Path (Get-Item -Path 'TestDrive:').FullName -ChildPath 'fubarsnafu'

        Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -Path $file -ErrorVariable 'errors'
        Assert-ConfigurationVariableSet -Path $file
        $errors | Should -BeNullOrEmpty
    }

    It 'using a relative path to a specific configuration file' {
        $testDriveRoot = (Get-Item -Path 'TestDrive:').FullName

        Push-Location -Path $testDriveRoot
        try
        {
            Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -Path 'fubarsnafu' -ErrorVariable 'errors'
            Assert-ConfigurationVariableSet -Path (Join-Path -Path $testDriveRoot -ChildPath 'fubarsnafu')
            $errors | Should -BeNullOrEmpty
        }
        finally
        {
            Pop-Location
        }
    }

    It 'setting global configuration and not in a repository' {
        $tempRoot = (Get-Item -Path 'TestDrive:').FullName
        Mock -CommandName 'Test-Path' -ModuleName 'GitAutomation' -ParameterFilter { $Path -eq 'env:HOME' } -MockWith { return $false }
        Push-Location -Path $tempRoot
        try
        {
            [LibGit2Sharp.GlobalSettings]::SetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global, ($tempRoot -replace '\\','/'))
            Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -Scope Global -ErrorVariable 'errors'
            Assert-ConfigurationVariableSet -Path '.gitconfig'
            $errors | Should -BeNullOrEmpty
        }
        finally
        {
            Pop-Location
        }
    }

    It 'HOME environment variable exists' {
        $tempDirPath = [IO.Path]::GetTempPath()

        [LibGit2Sharp.GlobalSettings]::SetConfigSearchPaths([LibGit2Sharp.ConfigurationLevel]::Global, ($tempDirPath -replace '\\','/') )
        $tempRoot = (Get-Item -Path 'TestDrive:').FullName
        Mock -CommandName 'Test-Path' -ModuleName 'GitAutomation' -ParameterFilter { $Path -eq 'env:HOME' } -MockWith { return $true }
        Mock -CommandName 'Get-Item' -ModuleName 'GitAutomation' -ParameterFilter { $Path -eq 'env:HOME' } -MockWith { return [pscustomobject]@{ Name = 'HOME' ; Value = (Get-Item -Path 'TestDrive:').FullName } }

        Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -Scope Global -ErrorVariable 'errors'
        Assert-ConfigurationVariableSet -Path (Join-Path -Path $tempRoot -ChildPath '.gitconfig')
        $errors | Should -BeNullOrEmpty

        Join-Path -Path $tempDirPath -ChildPath '.gitconfig' | Should -Not -Exist
    }
}
