function abort {
    foreach ($message in $args) { Write-Host $message -f red }
    exit 1
}
