function run($path, $route) {
    $executable = Join-Path $path -ChildPath "$(backslashify $route).ps1"

    if (!(Test-Path -Path $executable -PathType leaf)) {
        throw (_ 'Route {0} not found at path {1}' $route, $path)
    }

    $executable = fullpath($executable)
    & $executable @args
}
