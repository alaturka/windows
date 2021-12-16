function capture {
    process { $_ -replace '\s*$' -replace "`0" }
}
