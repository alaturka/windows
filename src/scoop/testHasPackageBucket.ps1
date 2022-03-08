function testHasPackageBucket($name) {
    @(scoop bucket list | Where-Object { $_.Name -eq $name }).Count -eq 1
}
