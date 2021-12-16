function invokePath {
    param (
        [Parameter(Mandatory)] [string] $route,
        [Parameter(Mandatory)] [string] $path,

        [Parameter(ValueFromRemainingArguments)] [string[]] $remainings
    )

    $executable = backslashify $route

    $executable = Join-Path $path -ChildPath "$executable.ps1"

    if (!(Test-Path -Path $executable -PathType leaf)) {
        throw (_ 'Route {0} not found at path {1}' $route, $path)
    }

    $executable = fullpath($executable)

    & $executable @remainings
}

function run { invokePath @args }
