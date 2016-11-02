
#Requires -Version 4
Set-StrictMode -Version 'Latest'

function Remove-LibGit2Module
{
    if( (Get-Module -Name 'LibGit2' ))
    {
        Remove-Module 'LibGit2'
    }
}

Describe 'LibGit2 when no HOME directory defined' {
    Remove-LibGit2Module
    Mock -CommandName 'Test-Path-Item' -ParameterFilter { $Path -eq 'env:HOME' } -MockWith { return $false }
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\LibGit2\Import-LibGit2.ps1' -Resolve)

    $expectedGlobalSearchPaths = @( ('{0}{1}' -f $env:HOMEDRIVE,$env:HOMEPATH)

}