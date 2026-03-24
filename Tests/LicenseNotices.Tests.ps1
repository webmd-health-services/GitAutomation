
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\Glob' -Resolve)
}

Describe 'License Notices' {
    It 'has license notice in all published files' {
        $projectRoot = Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve
        $licenseFilePath = Join-Path -Path $projectRoot -ChildPath 'LICENSE' -Resolve
        $moduleRoot = Join-Path -Path $projectRoot -ChildPath 'GitAutomation' -Resolve

        $noticeLines =
            Get-Content -Path $licenseFilePath -Tail 11 |
            ForEach-Object {
                $line = $_.Trim()
                if ($line)
                {
                    [regex]::Escape($line)
                }
            }

        $licenseNoticeRegex = '(?s){0}' -f ($noticeLines -join ('.+'))

        # $DebugPreference = 'Continue'
        $licenseNoticeRegex | Write-Debug

        $pathsToIgnore = @(
            '**\*.dll',
            '**\*.so',
            '**\*.dylib',
            '**\*.json',
            '**\*.pdb',
            '**\bin\**\*.config',
            '**\*.help.txt',
            'Functions\*.ps1',
            '*.md',
            'gitconfig',
            'NOTICE'
        )

        [object[]]$filesMissingLicense =
            Find-GlobFile -Path $moduleRoot -Exclude $pathsToIgnore |
            ForEach-Object {
                $fileInfo = $_
                $file = Get-Content -Path $fileInfo.FullName -Raw

                if( (-not $file) -or ($file -notmatch $licenseNoticeRegex))
                {
                    $fileInfo.FullName
                }
            }

        $filesMissingLicense | Should -BeNullOrEmpty
    }
}
