function reboot($message) {
    Write-Host
    foreach ($message in $args) { Write-Host $message -f yellow }
    Restart-Computer -Confirm -Force
}
