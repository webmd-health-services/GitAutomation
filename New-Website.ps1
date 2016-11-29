<#
.SYNOPSIS
Creates the get-libgit2.org website.

.DESCRIPTION
The `New-Website.ps1` script generates the get-libgit2.org website. It uses the Silk module for Markdown to HTML conversion.
#>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[CmdletBinding()]
param(
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

function Out-HtmlPage
{
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias('Html')]
        # The contents of the page.
        $Content,

        [Parameter(Mandatory=$true)]
        # The title of the page.
        $Title,

        [Parameter(Mandatory=$true)]
        # The path under the web root of the page.
        $VirtualPath
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
    }

    process
    {

        $webRoot = Join-Path -Path $PSScriptRoot -ChildPath 'get-libgit2.org'
        $path = Join-Path -Path $webRoot -ChildPath $VirtualPath
        $templateArgs = @(
                            $Title,
                            $Content,
                            (Get-Date).Year
                        )
        @'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <title>{0}</title>
    <link href="silk.css" type="text/css" rel="stylesheet" />
	<link href="styles.css" type="text/css" rel="stylesheet" />
</head>
<body>

    <ul id="SiteNav">
		<li><a href="index.html">Get-LibGit2</a></li>
        <li><a href="about_LibGit2_Installation.html">-Install</a></li>
		<li><a href="documentation.html">-Documentation</a></li>
        <li><a href="releasenotes.html">-ReleaseNotes</a></li>
		<li><a href="http://pshdo.com">-Blog</a></li>
        <li><a href="http://github.com/splatteredbits/LibGit2.PowerShell">-Project</a></li>
    </ul>

    {1}

	<div class="Footer">
		Copyright {2} <a href="http://pshdo.com">Aaron Jensen</a>.
	</div>

</body>
</html>
'@ -f $templateArgs | Set-Content -Path $path
    }

    end
    {
    }
}

$silkRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Silk' -Resolve

if( (Get-Module -Name 'Blade') )
{
    Remove-Module 'Blade'
}

$headingMap = @{ }

& (Join-Path -Path $silkRoot -ChildPath 'Import-Silk.ps1' -Resolve)
& (Join-Path -Path $PSScriptRoot -ChildPath '.\LibGit2\Import-LibGit2.ps1' -Resolve)

$websiteRoot = Join-Path -Path $PSScriptRoot -ChildPath 'get-libgit2.org'
if( -not (Test-Path -Path $websiteRoot -PathType Container) )
{
    Copy-GitRepository -Source 'https://github.com/pshdo/get-libgit2.org' -DestinationPath $websiteRoot
}

git -C $websiteRoot fetch
git -C $websiteRoot checkout master -q

try
{
    Convert-ModuleHelpToHtml -ModuleName 'LibGit2' -HeadingMap $headingMap -Script 'Import-LibGit2.ps1' |
        ForEach-Object { Out-HtmlPage -Title ('PowerShell - {0} - LibGit2' -f $_.Name) -VirtualPath ('{0}.html' -f $_.Name) -Content $_.Html }
}
finally
{
}

$tagsPath = Join-Path -Path $PSScriptRoot -ChildPath 'tags.json'
New-ModuleHelpIndex -TagsJsonPath $tagsPath -ModuleName 'LibGit2' -Script 'Import-LibGit2.ps1' |
     Out-HtmlPage -Title 'PowerShell - LibGit2 Module Documentation' -VirtualPath '/documentation.html'

$carbonTitle = 'LibGit2: PowerShell module for working with Git repositories'
Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'LibGit2\en-US\about_LibGit2.help.txt') |
    Convert-AboutTopicToHtml -ModuleName 'LibGit2' -Script 'Import-LibGit2.ps1' |
    ForEach-Object {
        $_ -replace '<h1>about_LibGit2</h1>','<h1>LibGit2</h1>'
    } |
    Out-HtmlPage -Title $carbonTitle -VirtualPath '/index.html'

$releaseNotesPath = Join-Path -Path $PSScriptRoot -ChildPath 'RELEASE_NOTES.md' 
Get-Content -Path $releaseNotesPath -Raw | 
    Edit-HelpText -ModuleName 'LibGit2' |
    Convert-MarkdownToHtml | 
    Out-HtmlPage -Title ('Release Notes - {0}' -f $carbonTitle) -VirtualPath '/releasenotes.html'

$silkCssPath = Join-Path -Path $silkRoot -ChildPath 'Resources\silk.css' -Resolve
$webroot = Join-Path -Path $PSScriptRoot -ChildPath 'get-libgit2.org'
Copy-Item -Path $silkCssPath -Destination $webroot -Verbose