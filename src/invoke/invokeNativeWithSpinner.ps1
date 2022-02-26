$Spinners = @(
    '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷',
    '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'
)

# Adapted from https://gist.github.com/yoav-lavi/1253321d968db7f52d1a77ac48e3ff96
function invokeNativeWithSpinner {
    param (
        [Parameter(Mandatory, Position = 0)] [string] $native,
        [Parameter(Mandatory              )] [string] $messageProgress,
                                             [string] $messageSuccess,
                                             [string] $messageFailure,

        [Parameter(ValueFromRemainingArguments, Position = 1)] [string[]] $remainings
    )

    $result = [PsCustomObject]@{
        Command   = $native
        Arguments = $remainings
        Output    = $null
        ExitCode  = $null
    }

    $job = [PowerShell]::Create().AddScript({
        param ($result)

        $arguments = $result.Arguments

        $result.Output   = & $result.Command @arguments 2>&1
        $result.ExitCode = $LastExitCode
    }).AddArgument($result)

    $async = $job.BeginInvoke()

    $i = 0
    while (!$async.IsCompleted) {
        $spinner = $Spinners[$i]
        Write-Host -NoNewLine "`r$spinner   $messageProgress" -ForegroundColor cyan

        Start-Sleep -Milliseconds 100

        if (++$i -eq $Spinners.Count) { $i = 0 }
    }

    $job.EndInvoke($async)

    # Flush prompt line: put space as long as the progress message length + 1 for prompt + 3 for space
    Write-Host -NoNewLine "`r$(' ' * $(1 + 3 + $messageProgress.Length))`r"

    if ($result.ExitCode -eq 0 -and ($PSBoundParameters.Keys -contains 'messageSuccess')) {
        Write-Host ">   $messageSuccess" -ForegroundColor cyan
    } elseif ($result.ExitCode -ne 0 -and ($PSBoundParameters.Keys -contains 'messageFailure')) {
        Write-Host ">   $messageFailure" -ForegroundColor red
        Write-Host
        Write-Host $result.Output
    }

    $result
}

function longexec { invokeNativeWithSpinner @args }
