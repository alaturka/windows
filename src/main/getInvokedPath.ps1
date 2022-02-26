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
