function testHasPackage($name) {
    @(scoop export | Where-Object { ($_ -split ' ')[0] -eq $name }).Count -eq 1
}
