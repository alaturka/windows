function testHasPackageBucket($name) {
    @(scoop bucket list | Where-Object { $_ -eq $name }).Count -eq 1
}
