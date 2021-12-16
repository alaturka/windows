function notice {
    foreach ($message in $args) { Write-Host $message -f yellow }
}
