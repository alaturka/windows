function invokeNative {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPositionalParameters', '')]
    param (
        [Parameter(Mandatory, Position = 0)] [string] $native,
                                             [string] $messageFailure,
                                             [switch] $com,
                                             [switch] $safe,

        [Parameter(ValueFromRemainingArguments, Position = 1)] [string[]] $remainings
    )

    $ErrorActionPreference = 'Stop'

    $message = if ($PSBoundParameters.Keys -contains 'messageFailure') {
        $messageFailure
    } else {
        (_ 'Command failed: {0}' "$native $remainings")
    }

    $failed, $detail = $false, $null

    try {
        if ($com) { & "$Env:COMSPEC" /d /c $native @remainings } else { & $native @remainings }

        $failed = $LastExitCode -ne 0
    }
    catch {
        $failed, $detail = $true, "$_"
    }

    if ($failed) {
        if (![String]::IsNullOrWhiteSpace($detail)) { Write-Warning $detail }
        if ($safe) { Write-Warning $message } else { throw $message }
    }
}

function exec { invokeNative @args }
function safeexec { invokeNative -Safe @args }
function cexec { invokeNative -Com @args }
function safecexec { invokeNative -Com -Safe @args }
function trueexec { try { invokeNative @args *>$null; return $true } catch { return $false } }
