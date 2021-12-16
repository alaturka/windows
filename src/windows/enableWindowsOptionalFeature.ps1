function enableWindowsOptionalFeature($feature) {
    $param = @{
        Online        = $true
        FeatureName   = $feature
        All           = $true
        NoRestart     = $true
        WarningAction = 'SilentlyContinue'
    }
    (Enable-WindowsOptionalFeature @param).RestartNeeded
}
