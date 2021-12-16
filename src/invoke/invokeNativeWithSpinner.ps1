$Spinners = @(
    '⣾⣿', '⣽⣿', '⣻⣿', '⢿⣿', '⡿⣿', '⣟⣿', '⣯⣿', '⣷⣿',
    '⣿⣾', '⣿⣽', '⣿⣻', '⣿⢿', '⣿⡿', '⣿⣟', '⣿⣯', '⣿⣷'
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
        $spinner =  $Spinners[$i]
        Write-Host -NoNewLine "`r$spinner  $messageProgress" -ForegroundColor cyan

        Start-Sleep -Milliseconds 100

        if (++$i -eq $Spinners.Count) { $i = 0 }
    }

    $job.EndInvoke($async)

    $lead = "`r$(' ' * $($Spinners[0].Length + $messageProgress.Length + 2))`r>$(' ' * $($Spinners[0].Length - 1))"

    if ($result.ExitCode -eq 0 -and ($PSBoundParameters.Keys -contains 'messageSuccess')) {
        Write-Host -NoNewLine "$lead  $messageSuccess" -ForegroundColor cyan
    } elseif ($result.ExitCode -ne 0 -and ($PSBoundParameters.Keys -contains 'messageFailure')) {
        Write-Host -NoNewLine "$lead  $messageFailure" -ForegroundColor red
        Write-Host
        Write-Host $result.Output
    }

    Write-Host

    $result
}

function longexec { invokeNativeWithSpinner @args }
