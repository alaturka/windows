#Requires -Version 5

# Write-Host 'Hello'

# Get-PSCallStack | Select-Object -Property *

# Taken from: https://stackoverflow.com/a/58289397
function getInvokedPath {
    $callStack = Get-PSCallStack

    $firstCall = $callStack[$callStack.Count - 1];
    if ($null -ne $firstCall.ScriptName) {
        return $firstCall.ScriptName
    }

    $secondCall = $callStack[$callStack.Count - 2];
    if ($null -ne $secondCall.ScriptName -and $secondCall.FunctionName -eq "<ScriptBlock>") {
        return $secondCall.ScriptName
    }

    $null
}

function dirname($path) {
    Split-Path -Path $path
}

# Stolen from Scoop source code
function fullpath($path) {
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
}

# function initialize {
#     $invokedPath = getInvokedPath

#     $invokedRoot = $null
#     if ($invokedPath) {
#         $invokedRoot = fullpath(dirname($invokedPath))
#     }

#     Write-Host (fullpath "$PSScriptRoot/../..")
#     exit

#     Write-Host "PSScriptRoot: |$($MyInvocation.PSScriptRoot)|"
#     Write-Host "invokedPath: |$invokedPath|"
#     Write-Host "invokedRoot: |$invokedRoot|"
# }

function initialize {
    $Path, $Local = if (getInvokedPath) {
        Write-Host "zzzzzzzzzzzzzzzzzzzzzzzz"
        (fullpath("$PSScriptRoot/../..")), $true
    } else {
        Write-Host "xxxxxxxxxxxxxxxxxxxxxxxxxx"
    }
    exit
}

function main {
    initialize
}

main
