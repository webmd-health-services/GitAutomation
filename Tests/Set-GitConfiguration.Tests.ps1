
#Requires -Version 4
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-LibGit2Test.ps1' -Resolve)

function Assert-ConfigurationVariableSet
{
    param(
        $Path
    )

    It 'should set the configuraton variable' {
        Get-Content -Path $Path | Where-Object { $_ -match 'autocrlf\ =\ false' } | Should Not BeNullOrEmpty
    }
}

Describe 'Set-GitConfiguration when setting the current repository''s configuration' {
    $repo = New-GitTestRepo
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

Describe 'Set-GitConfiguration when setting a specific repository''s configuration' {
    $repo = New-GitTestRepo

    Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -RepoRoot $repo
    Assert-ConfigurationVariableSet -Path (Join-Path -Path $repo -ChildPath '.git\config')
}

Describe 'Set-GitConfiguration when repo does not exist' {
    Set-GitConfiguration -Name 'core.autocrlf' -Value 'false' -RepoRoot (Get-Item -Path 'TestDrive:').FullName -ErrorVariable 'errors' -ErrorAction SilentlyContinue
    It 'should write an error' {
        $errors | Should Match 'valid Git repository'
    }
}

Describe 'Set-GitConfiguration when setting global configuration' {
    $value = [Guid]::NewGuid()
    Set-GitConfiguration -Name 'libgit2.test' -Value $value -Scope Global
    $repo = Find-GitRepository -Path $PSScriptRoot
    It 'should set option globally' {
        $option = $repo.Config | Where-Object { $_.Key -eq 'libgit2.test' -and $_.Value -eq $value -and $_.Level -eq [LibGit2Sharp.ConfigurationLevel]::Global } | Should Not BeNullOrEmpty
    }
}
