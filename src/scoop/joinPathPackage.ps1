function joinPathPackage($name) {
    $prefix = exec scoop prefix $name | capture
    Join-Path $prefix @args
}
