function IsInsideWindowsTerminal($process = (Get-Process -Id $PID)) {
    if (!$process) {
        return $false
    } elseif ($process.ProcessName -eq 'WindowsTerminal') {
        return $true
    } else {
        return IsInsideWindowsTerminal -childProcess $process.Parent
    }
}
