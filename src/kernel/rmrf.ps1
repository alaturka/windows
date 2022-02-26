function rmrf($dir) {
    if (Test-Path -Path $dir) {
        Remove-Item $dir -Recurse -Force -Confirm:$false
    }
}
