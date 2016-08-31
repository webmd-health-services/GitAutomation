
function Copy-GitRepository
{
    <#
    .SYNOPSIS
    Clones a Git repository.

    .DESCRIPTION
    The `Copy-GitRepository` function clones a Git repository from the URL specified by `Uri` to the path specified by `DestinationPath` and checks out the `master` branch. If the repository requires authentication, pass the username/password via the `Credential` parameter.

    To clone a local repository, pass a file system path to the `Uri` parameter.

    .EXAMPLE
    Copy-GitRepository -Uri 'https://github.com/splatteredbits/LibGit2.PowerShell' -DestinationPath LibGit2.PowerShell
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The URI or path to the source repository to clone.
        $Source,

        [Parameter(Mandatory=$true)]
        [string]
        # The directory where the repository should be cloned to. Must not exist or be empty.
        $DestinationPath,

        [pscredential]
        # The credentials to use to connect to the source repository.
        $Credential,

        [Switch]
        # Returns a `System.IO.DirectoryInfo` object for the new copy's `.git` directory.
        $PassThru
    )

    Set-StrictMode -Version 'Latest'

    $Source = ConvertTo-FullPath -Uri $Source
    $DestinationPath = ConvertTo-FullPath -Path $DestinationPath

    $options = New-Object 'libgit2sharp.CloneOptions'
    if( $Credential )
    {
        $gitCredential = New-Object 'LibGit2Sharp.SecureUsernamePasswordCredentials'
        $gitCredential.Username = $Credential.UserName
        $gitCredential.Password = $Credential.Password
        $options.CredentialsProvider = { return $gitCredential }
    }

    $cancelClone = $false
    $options.OnProgress = { 
        param(
            $Output
        )

        Write-Verbose -Message $Output
        return -not $cancelClone
    }

    $options.OnTransferProgress = { 
        param(
            [LibGit2Sharp.TransferProgress]
            $TransferProgress
        )

        $numBytes = $TransferProgress.ReceivedBytes
        if( $numBytes -lt 1kb )
        {
            $unit = 'B'
        }
        elseif( $numBytes -lt 1mb )
        {
            $unit = 'KB'
            $numBytes = $numBytes / 1kb
        }
        elseif( $numBytes -lt 1gb )
        {
            $unit = 'MB'
            $numBytes = $numBytes / 1mb
        }
        elseif( $numBytes -lt 1tb )
        {
            $unit = 'GB'
            $numBytes = $numBytes / 1gb
        }
        elseif( $numBytes -lt 1pb )
        {
            $unit = 'TB'
            $numBytes = $numBytes / 1tb
        }
        else
        {
            $unit = 'PB'
            $numBytes = $numBytes / 1pb
        }

        Write-Progress -Activity ('Cloning {0} -> {1}' -f $Source,$DestinationPath) `
                       -Status ('{0}/{1} objects, {2:n0} {3}' -f $TransferProgress.ReceivedObjects,$TransferProgress.TotalObjects, $numBytes,$unit) `
                       -PercentComplete (($TransferProgress.ReceivedObjects / $TransferProgress.TotalObjects) * 100)
        return (-not $cancelClone)
    }

    try
    {
        $cloneCompleted = $false
        $gitPath = [LibGit2Sharp.Repository]::Clone($Source, $DestinationPath, $options)
        if( $PassThru -and $gitPath )
        {
            Get-Item -Path $gitPath -Force
        }
        $cloneCompleted = $true
    }
    finally
    {
        if( -not $cloneCompleted )
        {
            $cancelClone = $true
        }
    }
}