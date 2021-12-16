function testHasCommand($name) {
    [boolean](Get-Command $name -ErrorAction Ignore)
}
