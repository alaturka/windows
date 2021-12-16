#Requires -Version 5

# --- Support

[cmdletbinding()]
param()

. "$PSScriptRoot\lib\support.ps1"

function invokeBlockWithRetry {
    param (
        [Parameter(Mandatory)] [scriptblock] $block,
                               [int]         $try            = 2,
                               [int]         $delay          = 1000,
                               [string]      $messageFailure = (_ 'Operation failed')
    )

    $ErrorActionPreference = 'Stop'

    $attempt = 0

    do {
        $attempt++

        try {
            Set-Strictmode -Off
            return ($block.Invoke())
        } catch {
            Write-Verbose (_ 'Retrying failed operation: {0}' $_.Exception.InnerException.Message)
            Start-Sleep -Milliseconds $delay
        }
    } while ($attempt -lt $try)

    throw $messageFailure
}

function insistentcall { invokeBlockWithRetry @args }

$Script:try = 0

function enableOpt {
    if ($Script:try -eq 0) {
        $Script:try += 1

        throw 'first fail'
    }
    throw 'second fail'
    # Write-Host "SUCCESS"

    return 19
}

function enableFeat {
    $param = @{
        Online        = $true
        FeatureName   = 'hmm'
        All           = $true
        NoRestart     = $true
        WarningAction = 'SilentlyContinue'
    }

    $result = try {
        enableOpt($param)
    } catch {
        Write-Host "$_"
        enableOpt
    }

    Write-Host "|$result|"
}

function main {
    # $result = [void](insistentcall { enableWindowsOptionalFeature 'Microsoft-Windows-Subsystem-Linux' })
    # [void]($result = insistentcall { getWindowsOptionalFeature 'Microsoft-Windows-Subsystem-Linux' } -MessageFailure 'ERORRRRRRRRRRRR')
    [void]($result = insistentcall { enableOpt } -MessageFailure 'ERORRRRRRRRRRRR')
    Write-Host "|$result|"
    # $result = insistentcall { enableWindowsOptionalFeature 'Microsoft-Windows-Subsystem-Linux' }
}

main @args

# vim: et ts=4 sw=4 sts=4 tw=120
