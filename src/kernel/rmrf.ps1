function rmrf {
    foreach ($dir in $args) {
        if (Test-Path -Path $dir) {
            Remove-Item $dir -Recurse -Force -Confirm:$false
        }
    }
}
