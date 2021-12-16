function getWindowsOptionalFeature($feature) {
    $result = Get-WindowsOptionalFeature -FeatureName $feature -Online

    $isEnabled    = $result.State -eq 'Enabled'
    $isActionable = $result.RestartNeeded -or !$isEnabled
    $isRestart    = $result.RestartNeeded

    @{
        Actionable = $isActionable
        Enabled    = $isEnabled
        Restart    = $isRestart
    }
}
