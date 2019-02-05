
[![Build status](https://ci.appveyor.com/api/projects/status/pm83uey7k498pe9d?svg=true)](https://ci.appveyor.com/project/WebMD-Health-Services/gitautomation)
[![latest](https://img.shields.io/badge/dynamic/json.svg?label=latest&url=https%3A%2F%2Fapi.github.com%2Frepos%2Fwebmd-health-services%2FGitAutomation%2Freleases%2Flatest&query=%24.name&colorB=brightgreen)](https://www.powershellgallery.com/packages/BitbucketServerAutomation)

# Overview
GitAutomation is a PowerShell module for working with Git repositories. You can use it to create, clone, query, push, pull, commit, and even more with Git repositories.

This module uses [LibGit2Sharp](https://github.com/libgit2/libgit2sharp), the .NET wrapper of [libgit2](https://libgit2.org/), "a portable, pure C implementation of... Git", which allows you to call Git via API instead using the Git command line interface.

# Installation

## Install from PowerShell Gallery

 Ensure you have [PowerShellGet](https://docs.microsoft.com/en-us/powershell/gallery/installing-psget) installed and make [PowerShell Gallery](https://www.powershellgallery.com/) a trusted source:

    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

 Then to install the module run:

    Install-Module -Name GitAutomation

# Contributing

Contributions are welcome and encouraged!

## Building and Testing

We use [Whiskey](https://github.com/webmd-health-services/Whiskey) to build, test, and publish the module. [Pester](https://github.com/pester/Pester) is the testing framework used for our tests.

To build and run all tests, use the `build.ps1` script:

    .\build.ps1

If you want to run only specific tests, first import `Pester`:

    Import-Module -Name '.\PSModules\Pester'

Then invoke a single test script:

    Invoke-Pester -Path .\Tests\New-BBServerRepository.Tests.ps1

Test scripts go in the `Tests` directory. New module functions go in the `GitAutomation\Functions` directory.
