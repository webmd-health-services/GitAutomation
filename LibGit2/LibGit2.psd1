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

@{

# Script module or binary module file associated with this manifest.
RootModule = 'LibGit2.psm1'

# Version number of this module.
ModuleVersion = '0.1.0'

# ID used to uniquely identify this module
GUID = '119a2511-62d9-4626-9728-0c8ec7068c57'

# Author of this module
Author = 'Aaron Jensen'

# Company or vendor of this module
CompanyName = ''

# Copyright statement for this module
Copyright = 'Copyright 2016 Aaron Jensen'

# Description of the functionality provided by this module
Description = @'
LibGit2 is a PowerShell module for working with Git repositories. You can use it to create, clone, query, push to, pull from, and commit to Git repositories.
    
This module uses the .NET wrapper of [libgit2](https://libgit2.github.com/), "a portable, pure C implementation of... Git", which allows you to call Git via API instead using the Git command line interface.
'@

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @( 'bin\LibGit2Sharp.dll', 'bin\LibGit2.Automation.dll' )

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
TypesToProcess = @( 'Types\LibGit2Sharp.StatusEntry.types.ps1xml' )

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = @( 'Formats\LibGit2Sharp.StatusEntry.formats.ps1xml' )

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = @(
                        'Add-GitItem',
                        'Copy-GitRepository',
                        'Find-GitRepository',
                        'Get-GitRepository',
                        'Get-GitRepositoryStatus',
                        'New-GitRepository',
                        'Save-GitChange'
                    )

# Cmdlets to export from this module
#CmdletsToExport = '*'

# Variables to export from this module
#VariablesToExport = '*'

# Aliases to export from this module
#AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('git','vcs','rcs','automation','github','gitlab','libgit2')

        # A URL to the license for this module.
        LicenseUri = 'http://www.apache.org/licenses/LICENSE-2.0'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/splatteredbits/LibGit2.PowerShell/wiki'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = @'
* Created `Add-GitItem` function for promoting new, untracked, and modified files/directories to the Git staging area so they can be committed. Implements the `git add` command.
 * Created `Get-GitRepository` function for getting an object representing a repository.
 * Created `Save-GitChange` function for commiting changes to a repository. Implements the `git commit` command.
 * Created `Find-GitRepository` function for searching a directory and its parents (i.e. up it tree) for a Git repository.
 * Created `New-GitRepository` function for creating new Git repositories.
 * Created `Get-GitRepositorStatus` function for getting the state of a repository's working directory and any items staged for the next commit.
'@

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
#DefaultCommandPrefix = 'Git'

}

