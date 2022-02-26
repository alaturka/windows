function getvar($name, $default = $null) {
    if (Test-path "variable:$name") {
        (Get-Item "variable:$name").Value
    } else {
        $default
    }
}
