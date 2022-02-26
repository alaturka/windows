function testHasWSLDistribution($distribution) {
    wsl --list --quiet | capture | Select-String $distribution
}
