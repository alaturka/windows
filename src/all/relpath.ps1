function relpath($path) {
    Join-Path $MyInvocation.PSScriptRoot -ChildPath $path
}
