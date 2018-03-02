function Invoke-WhiskeyExec
{
    <#
    .SYNOPSIS
    Runs an executable.
    
    .DESCRIPTION
    The `Exec` task runs an executable. Specify the path to the executable to run with the task's `Path` property. The `Path` can be the name of an executable that can be found in the `PATH` environment variable, a path relative to your `whiskey.yml` file's directory, or an absolute path.

    The task will fail if the executable returns a non-zero exit code. Use the `SuccessExitCode` property to configure the task to interpret other exit codes as "success". 

    Pass arguments to the executable via the `Argument` property. The `Exec` task uses PowerShell's `Start-Process` cmdlet to run the executable, so that arguments will be passes as-is, with no escaping. YAML strings, however, are usually single-quoted (e.g. `'Value'`) or double-quoted (e.g. `"Value"`). If you're using a single quoted string and need to insert a single quote, escape it by using two single quotes, e.g. `'escape: '''` is converted to `escape '`. If you're using a double-quoted string and need to insert a double quote, escape it with `\`, e.g. `"escape: \""` is converted to `escape: "`. YAML supports other escape sequences in double-quoted strings. The full list of escape sequences is in the [YAML specification](http://yaml.org/spec/current.html#escaping in double quoted style/).

    The `Exec` task supports a simplified single line syntax to define the `Path` and optional `Arguments` properties. Anything enclosed by single-quote or double-quote characters are treated as an individual path or argument. Otherwise, white-space is the default delimiter separating items.

    By default, the executable is run from your `whiskey.yml` file's directory (i.e. the build root). Change the working directory with the `WorkingDirectory` property.

    The "Exec" task runs in all modes: during initialization, build, and clean modes. If you want executable to only run in one mode, use the `OnlyDuring` property to specify the only mode you want it to run in or the `ExceptDuring` property to specify the run mode you don't want it to run in. 

    # Properties

    * `Path` (*mandatory*): the path to the executable to run. This can be the name of an executable if it is in your PATH environment variable, a path relative to the `whiskey.yml` file, or an absolute path.
    * `Argument`: a list of arguments to pass to the executable. Read the documentation above for notes on how to properly escape arguments.
    * `WorkingDirectory`: the directory the executable will run in/from. By default, this is the build root, i.e. the `whiskey.yml` file's directory.
    * `SuccessExitCode`: a list of exit codes that the `Exec` task should interpret to mean the executable's process exited successfully. The list can include individual exit codes and certain range operators (ie. '>=1', '<=2', '>3', '<4', '5..10' ). An exit code only needs to match a single code or range to be evaluated as successful. The default is `0`

    # Examples

    ## Example 1

        BuildTasks:
        - Exec:
            Path: cmd.exe
            Argument:
            - /C
            - dir C:\

    This example demonstrates how to call an executable whose arguments have to be quoted a specific way. In this case, we're using `cmd.exe` to get a directory listing of the `C:\` directory. This example will run `cmd.exe /C dir C:\.

    ## Example 2

        BuildTasks:
        - Exec:
            Path: robocopy.exe
            Argument:
            - C:\Source
            - C:\Destination
            - /MIR    
            SuccessExitCode:
            - 10
            - 12
            - <8
            - >=28

    This example demonstrates how to configure the `Exec` task to fail when an executable can return multiple success exit codes. In this case, `robocopy.exe` can return any value less than 8, greater than or equal to 28, 10, or 12, to report a successful copy.

    ## Example 3

            BuildTasks:
            - Exec: robocopy.exe "C:\Source Folder" C:\Destination Folder '/MIR'

    This example demonstrates the single line syntax for defining the `Exec` task. Everything before the first delimiter is used as the executable's `Path` (robocopy.exe). 'C:\Source Folder', 'C:\Destination', 'Folder' and '/MIR' will be passed as 4 separate arguments.

    ### Example 4

        BuildTasks:
        - Exec:
            ExceptDuring: Clean
            Path: cmd.exe
            Argument:
            - /C
            - init.bat

    Demonstrates how to run an executable except when the build is cleaning. If you have an executable you want to use to initialize your build environment, it should run during the build and initialize modes. Set the `ExceptDuring` property to `Clean` to make that happen.

    ### Example 5

        BuildTasks:
        - Exec:
            OnlyDuring: Clean
            Path: cmd.exe
            Argument:
            - /C
            - clean.bat

    Demonstrates how to run an executable in a specific mode. In this example, the cmd.exe executable will only run the clean.bat script when the build is cleaning.
    #>      
    [CmdletBinding()]
    [Whiskey.Task("Exec",SupportsClean=$true,SupportsInitialize=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( $TaskParameter.ContainsKey('') )
    {
        $regExMatches = Select-String -InputObject $TaskParameter[''] -Pattern '([^\s"'']+)|("[^"]*")|(''[^'']*'')' -AllMatches
        $defaultProperty = @($regExMatches.Matches.Groups | Where-Object { $_.Name -ne '0' -and $_.Success -eq $true } | Select-Object -ExpandProperty 'Value')

        $TaskParameter['Path'] = $defaultProperty[0]
        if( $defaultProperty.Count -gt 1 )
        {
            $TaskParameter['Argument'] = $defaultProperty[1..($defaultProperty.Count - 1)] | ForEach-Object { $_.Trim("'",'"') }
        }
    }

    $path = $TaskParameter['Path']
    if ( -not $path )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''Path'' is mandatory. It should be the Path to the executable you want the Exec task to run, e.g.
        
            BuildTasks:
            - Exec:
                Path: cmd.exe
            
        ')
    }

    if ( -not [IO.Path]::IsPathRooted($path) )
    {
        $path = Join-Path -Path $TaskContext.BuildRoot -ChildPath $path
    }
    
    if ( (Test-Path -Path $path -PathType Leaf) )
    {
        $path = $path | Resolve-Path | Select-Object -ExpandProperty 'ProviderPath'
    }
    else
    {
        $path = $TaskParameter['Path']
        if( -not (Get-Command -Name $path -CommandType Application -ErrorAction Ignore) )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Executable ''{0}'' does not exist. We checked if the executable is at that path on the file system and if it is in your PATH environment variable.' -f $path)
        }
    }

    $logArgumentList = $TaskParameter['Argument'] | 
                            ForEach-Object { 
                                if( $_ -match '\ ' ) 
                                {
                                    '"{0}"' -f $_.Trim('"',"'")
                                }
                                else
                                {
                                    $_
                                }
                            }
    Write-WhiskeyInfo -Context $TaskContext -Message ('{0} {1}' -f $path,($logArgumentList -join ' '))
    Write-WhiskeyVerbose -Context $TaskContext -Message ($path)
    $argumentPrefix = ' ' * ($path.Length + 2)
    foreach( $argument in $TaskParameter['Argument'] )
    {
        Write-WhiskeyVerbose -Context $TaskContext -Message ('{0}{1}' -f $argumentPrefix,$argument)
    }
    # Don't use Start-Process. If/when a build runs in a background job, when Start-Process finishes, it immediately terminates the build. Full stop.
    & $path $TaskParameter['Argument']
    $exitCode = $LASTEXITCODE
    
    $successExitCodes = $TaskParameter['SuccessExitCode']
    if( -not $successExitCodes )
    {
        $successExitCodes = '0'
    }

    foreach( $successExitCode in $successExitCodes )
    {
        if( $successExitCode -match '^(\d+)$' )
        {
            if( $exitCode -eq [int]$Matches[0] )
            {
                Write-WhiskeyVerbose -Context $TaskContext -Message ('Exit Code {0} = {1}' -f $exitCode,$Matches[0])
                return
            }
        }
        
        if( $successExitCode -match '^(<|<=|>=|>)\s*(\d+)$' )
        {
            $operator = $Matches[1]
            $successExitCode = [int]$Matches[2]
            switch( $operator )
            {
                '<'
                {
                    if( $exitCode -lt $successExitCode )
                    {
                        Write-WhiskeyVerbose -Context $TaskContext -Message ('Exit Code {0} < {1}' -f $exitCode,$successExitCode)
                        return
                    }
                }
                '<='
                {
                    if( $exitCode -le $successExitCode )
                    {
                        Write-WhiskeyVerbose -Context $TaskContext -Message ('Exit Code {0} <= {1}' -f $exitCode,$successExitCode)
                        return
                    }
                }
                '>'
                {
                    if( $exitCode -gt $successExitCode )
                    {
                        Write-WhiskeyVerbose -Context $TaskContext -Message ('Exit Code {0} > {1}' -f $exitCode,$successExitCode)
                        return
                    }
                }
                '>='
                {
                    if( $exitCode -ge $successExitCode )
                    {
                        Write-WhiskeyVerbose -Context $TaskContext -Message ('Exit Code {0} >= {1}' -f $exitCode,$successExitCode)
                        return
                    }
                }
            }
        }
        
        if( $successExitCode -match '^(\d+)\.\.(\d+)$' )
        {
            if( $exitCode -ge [int]$Matches[1] -and $exitCode -le [int]$Matches[2] )
            {
                Write-WhiskeyVerbose -Context $TaskContext -Message ('Exit Code {0} <= {1} <= {2}' -f $Matches[1],$exitCode,$Matches[2])
                return
            }
        }
    }
    
    Stop-WhiskeyTask -TaskContext $TaskContext -Message ('''{0}'' returned with an exit code of ''{1}''. View the build output to see why the executable''s process failed.' -F $TaskParameter['Path'],$exitCode)
}
